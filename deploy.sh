#!/bin/bash
set -e

# Configuration
DOMAIN="testsiteem.duckdns.org"
PROJECT_DIR="/opt/projet-site"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"

echo "=== 1. Mise à jour et installation des dépendances ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get remove -y docker docker-engine docker.io containerd runc || true
apt-get autoremove -y
apt-get install -y python3-venv certbot docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== 2. Gestion du certificat SSL (via pip) ==="
if [ ! -d "/opt/certbot-venv" ]; then
    python3 -m venv /opt/certbot-venv
    /opt/certbot-venv/bin/pip install --upgrade pip
    /opt/certbot-venv/bin/pip install certbot certbot-dns-duckdns
fi

if [ ! -f "$CERT_PATH" ]; then
    if [ ! -f "/root/.secrets/duckdns.ini" ]; then
        echo "Erreur : /root/.secrets/duckdns.ini manquant."
        exit 1
    fi
    
    /opt/certbot-venv/bin/certbot certonly \
      --authenticator dns-duckdns \
      --dns-duckdns-credentials /root/.secrets/duckdns.ini \
      --dns-duckdns-propagation-seconds 60 \
      --agree-tos \
      --register-unsafely-without-email \
      -d "$DOMAIN" \
      --non-interactive
fi

echo "=== 3. Configuration Nginx Sécurisée ==="
mkdir -p "$PROJECT_DIR/nginx"
cat << 'EOT' > "$PROJECT_DIR/nginx/default.conf"
server {
    listen 80;
    server_name testsiteem.duckdns.org;
    location / { return 301 https://$host$request_uri; }
}

server {
    listen 443 ssl;
    server_name testsiteem.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/testsiteem.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/testsiteem.duckdns.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self';" always;

    location / {
        proxy_pass http://web_app:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOT

echo "=== 4. Lancement des services ==="
cd "$PROJECT_DIR"
# Nettoyage des orphelins pour éviter les conflits de ports
docker compose down --remove-orphans
docker compose up -d --remove-orphans

echo "=== Déploiement terminé ! ==="
