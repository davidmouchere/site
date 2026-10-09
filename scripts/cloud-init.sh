#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo "=== 1. Installation des prérequis ==="
apt-get update
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release ufw fail2ban git python3-pip python3-venv

echo "=== 2. Installation de Docker ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker && systemctl start docker

echo "=== 3. Préparation du site et des certificats ==="
mkdir -p /opt/projet-site/site /opt/projet-site/nginx /etc/letsencrypt
# Copie du contenu du repo vers le dossier site
git clone https://github.com/davidmouchere/site.git /opt/projet-site/repo-temp
cp -r /opt/projet-site/repo-temp/* /opt/projet-site/site/ 2>/dev/null || cp -r /opt/projet-site/repo-temp/site/* /opt/projet-site/site/
rm -rf /opt/projet-site/repo-temp

# Configuration des secrets pour DuckDNS
mkdir -p /root/.secrets
echo "dns_duckdns_token = @@DUCKDNS_TOKEN@@" > /root/.secrets/duckdns.ini
chmod 600 /root/.secrets/duckdns.ini

# Installation de Certbot
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-dns-duckdns

# Copie des fichiers de config du projet vers /opt/projet-site
# (On suppose que le repo est cloné ou présent, ici on utilise les fichiers du projet)
# Note: Dans un vrai déploiement, on copierait le dossier projet complet.
# Ici, on crée les fichiers nécessaires.
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

# Lancement initial
cd /opt/projet-site && docker compose up -d

# Récupération du certificat
/opt/certbot/bin/certbot certonly --authenticator dns-duckdns \
  --dns-duckdns-credentials /root/.secrets/duckdns.ini \
  --dns-duckdns-propagation-seconds 60 \
  --agree-tos --register-unsafely-without-email \
  -d @@DOMAIN_NAME@@ --non-interactive

# Configuration Nginx HTTPS définitive
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
    location / {
        proxy_pass http://web_app:80;
    }
}
EOF
docker compose restart reverse-proxy
