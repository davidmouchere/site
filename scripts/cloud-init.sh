#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo "=== 1. Installation des prérequis ==="
apt-get update
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release ufw fail2ban git python3-pip python3-venv

echo "=== 2. Sécurisation SSH (Clés uniquement, désactivation des mots de passe) ==="
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

echo "=== 3. Configuration de Fail2ban ==="
cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 192.168.27.0/24 82.67.129.161

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = %(nginx_error_log)s

[nginx-botsearch]
enabled = true
port = http,https
logpath = %(nginx_error_log)s
maxretry = 2
EOF
systemctl enable fail2ban
systemctl restart fail2ban

echo "=== 4. Installation de Docker ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker && systemctl start docker

echo "=== 5. Préparation du site et des certificats ==="
mkdir -p /opt/projet-site/site /opt/projet-site/nginx /etc/letsencrypt
git clone https://github.com/davidmouchere/site.git /opt/projet-site/repo-temp
cp -r /opt/projet-site/repo-temp/* /opt/projet-site/site/ 2>/dev/null || cp -r /opt/projet-site/repo-temp/site/* /opt/projet-site/site/
rm -rf /opt/projet-site/repo-temp

mkdir -p /root/.secrets
echo "dns_duckdns_token = @@DUCKDNS_TOKEN@@" > /root/.secrets/duckdns.ini
chmod 600 /root/.secrets/duckdns.ini

python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-dns-duckdns

cat << 'EOF' > /opt/projet-site/docker-compose.yml
services:
  web:
    image: nginx:alpine
    container_name: web_app
    restart: always
    volumes: ["./site:/usr/share/nginx/html:ro"]
  reverse-proxy:
    image: nginx:alpine
    container_name: reverse_proxy
    restart: always
    ports: ["80:80", "443:443"]
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on: ["web"]
EOF

cat << 'EOF' > /opt/projet-site/nginx/default.conf
server {
    listen 80;
    server_name @@DOMAIN_NAME@@;
    location / {
        proxy_pass http://web_app:80;
    }
}
EOF

cd /opt/projet-site && docker compose up -d

/opt/certbot/bin/certbot certonly --authenticator dns-duckdns \
  --dns-duckdns-credentials /root/.secrets/duckdns.ini \
  --dns-duckdns-propagation-seconds 60 \
  --agree-tos --register-unsafely-without-email \
  -d @@DOMAIN_NAME@@ --non-interactive

cat << 'EOF' > /opt/projet-site/nginx/default.conf
server {
    listen 80;
    server_name @@DOMAIN_NAME@@;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name @@DOMAIN_NAME@@;
    ssl_certificate /etc/letsencrypt/live/@@DOMAIN_NAME@@/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/@@DOMAIN_NAME@@/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    location / {
        proxy_pass http://web_app:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
docker compose restart reverse-proxy
