#!/bin/bash
# Arrêter le script en cas d'erreur
set -e

VM_USER="ubuntu"
SSH_KEY="$HOME/.ssh/oracle"
VM_IPS=("129.151.247.30" "82.70.230.163")

LOCAL_SITE_DIR="/home/david/projet/site/"
REMOTE_SITE_DIR="/opt/projet-site/site/"

echo "=== Déploiement sur les VM Web ==="

for VM_IP in "${VM_IPS[@]}"; do
    echo "--------------------------------------------------"
    echo "🚀 Traitement de la VM : $VM_IP"
    echo "--------------------------------------------------"

    echo "1. Envoi des fichiers du site..."
    rsync -avz -e "ssh -i $SSH_KEY" "$LOCAL_SITE_DIR" "$VM_USER@$VM_IP:$REMOTE_SITE_DIR"

    echo "2. Mise à jour automatique du script de la VM..."
    ssh -i "$SSH_KEY" "$VM_USER@$VM_IP" 'cat << "EOF" > ~/update_site.sh
#!/bin/bash
set -e
PROJ_DIR="/opt/projet-site"
echo "=== Actualisation du site sur la VM ==="
if [ -d "$PROJ_DIR/docker" ]; then
    cd "$PROJ_DIR/docker"
    docker compose up -d --build
fi
echo "=== Terminé ! ==="
EOF
chmod +x ~/update_site.sh
'

    echo "3. Exécution du script sur la VM..."
    ssh -i "$SSH_KEY" "$VM_USER@$VM_IP" "./update_site.sh"

    echo "✅ VM $VM_IP mise à jour avec succès !"
done

echo "=================================================="
echo "🎉 Déploiement terminé sur toutes les VM !"
echo "=================================================="

