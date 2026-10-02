import base64

with open("site/index.html", "r", encoding="utf-8") as f:
    idx = f.read()
with open("site/tarifs.html", "r", encoding="utf-8") as f:
    tar = f.read()
with open("site/style.css", "r", encoding="utf-8") as f:
    css = f.read()
with open("site/mains.jpg", "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode("utf-8")

script_content = f"""#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release ufw fail2ban git unattended-upgrades certbot
dpkg-reconfigure -f noninteractive unattended-upgrades

HOSTNAME=\$(hostname)
if [[ "\$HOSTNAME" == *"1"* ]]; then
    REBOOT_TIME="03:00"
else
    REBOOT_TIME="03:30"
fi

cat << EOF > /etc/apt/apt.conf.d/50unattended-upgrades-custom
Unattended-Upgrade::Allowed-Origins {{
    "\\${distro_id}:\\${distro_codename}-security";
}};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "\\$REBOOT_TIME";
EOF

systemctl enable fail2ban
systemctl start fail2ban

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \\
  "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \\
  \$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

mkdir -p /opt/projet-site/site /opt/projet-site/nginx

cat << 'EOF' > /opt/projet-site/nginx/default.conf
server {{
    listen 80;
    server_name testsiteem.duckdns.org;

    location /.well-known/acme-challenge/ {{
        root /var/www/certbot;
    }}

    location / {{
        return 301 https://\\$host\\$request_uri;
    }}
}}

server {{
    listen 443 ssl;
    server_name testsiteem.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/testsiteem.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/testsiteem.duckdns.org/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {{
        proxy_pass http://web_app:80;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }}
}}
EOF

cat << 'EOF' > /opt/projet-site/docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    container_name: web_app
    restart: always
    volumes:
      - ./site:/usr/share/nginx/html:ro
    networks:
      - webnet

  reverse-proxy:
    image: nginx:alpine
    container_name: reverse_proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./site:/usr/share/nginx/html:ro
      - /var/www/certbot:/var/www/certbot
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - web
    networks:
      - webnet

  diun:
    image: crazymax/diun:latest
    container_name: diun
    restart: always
    command: serve
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./diun-data:/data"
    environment:
      - TZ=Europe/Paris
      - LOG_LEVEL=info
      - LOG_JSON=false
      - DIUN_WATCH_WORKERS=5
      - DIUN_WATCH_SCHEDULE=0 */6 * * *
      - DIUN_PROVIDERS_DOCKER=true
      - DIUN_PROVIDERS_DOCKER_WATCHBYDEFAULT=true
    networks:
      - webnet

networks:
  webnet:
    driver: bridge
EOF

cat << 'EOF' > /opt/projet-site/site/index.html
{idx}
EOF

cat << 'EOF' > /opt/projet-site/site/tarifs.html
{tar}
EOF

cat << 'EOF' > /opt/projet-site/site/style.css
{css}
EOF

echo "{img_b64}" | base64 -d > /opt/projet-site/site/mains.jpg

# Génération initiale du certificat Let's Encrypt (avant de lancer le proxy)
mkdir -p /var/www/certbot
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d testsiteem.duckdns.org --non-interactive || true

cd /opt/projet-site
docker compose up -d

# Redémarrage du proxy pour prendre en compte le certificat s'il a pu être généré
docker compose restart reverse-proxy

# Ajout d'une tâche cron pour le renouvellement automatique des certificats
(crontab -l 2>/dev/null; echo "0 4 * * * certbot renew --quiet && docker compose -f /opt/projet-site/docker-compose.yml restart reverse-proxy") | crontab -

cat << 'EOF' > /opt/projet-site/stress_cpu.sh
#!/bin/bash
DURATION=60
CORES=$(nproc)
PIDS=()
for ((i=1; i<=CORES; i++)); do
    python3 -c "while True: pass" &
    PIDS+=($!)
done
sleep $DURATION
for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null
done
sleep 2
RESIDUAL=$(ps aux | grep "[p]ython3 -c while True: pass" | wc -l)
if [ "$RESIDUAL" -gt 0 ]; then
    pkill -9 -f "python3 -c while True: pass"
fi
EOF

chmod +x /opt/projet-site/stress_cpu.sh
(crontab -l 2>/dev/null; echo "0 4 * * 0 /opt/projet-site/stress_cpu.sh >> /var/log/stress_cpu.log 2>&1") | crontab -
echo "Cloud-init terminé."
"""

with open("scripts/cloud-init.sh", "w", encoding="utf-8") as f:
    f.write(script_content)
print("Génération réussie.")
