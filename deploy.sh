#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "=== 1. Configuration non-interactive pour éviter les blocages de redémarrage de services ==="
export DEBIAN_FRONTEND=noninteractive

echo "=== 2. Installation de Certbot et des dépendances si nécessaire ==="
if ! command -v certbot &> /dev/null; then
    echo "Installation de certbot..."
    sudo apt-get update
    # Utilisation de needrestart en mode automatique pour éviter les prompts bloquants
    sudo NEEDRESTART_MODE=a apt-get install -y certbot python3-pip
    sudo pip3 install --no-cache-dir certbot-dns-duckdns
fi

# Vérification du token DuckDNS
DOMAIN="testsiteem.duckdns.org"
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "Certificat introuvable pour $DOMAIN. Génération via DuckDNS..."
    
    if [ ! -f "/root/.secrets/duckdns.ini" ]; then
        echo "Erreur : Le fichier /root/.secrets/duckdns.ini est requis avec votre token DuckDNS."
        exit 1
    fi

    sudo certbot certonly \
      --authenticator dns-duckdns \
      --dns-duckdns-credentials /root/.secrets/duckdns.ini \
      --dns-duckdns-propagation-seconds 60 \
      --agree-tos \
      --register-unsafely-without-email \
      -d "$DOMAIN" \
      --non-interactive
else
    echo "Certificat Let's Encrypt déjà présent."
fi

echo "=== 3. Lancement / Mise à jour des conteneurs Docker ==="
docker compose down || true
docker compose up -d

echo "=== Déploiement terminé avec succès ! ==="
