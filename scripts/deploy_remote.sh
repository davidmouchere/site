#!/bin/bash
# IP de l'instance
INSTANCE_IP="84.235.232.124"

echo "Déploiement sur l'instance : $INSTANCE_IP"

# Copie des fichiers nécessaires
# On s'assure que le dossier distant existe
ssh -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo mkdir -p /opt/projet-site"

scp -o StrictHostKeyChecking=no ~/projet/deploy.sh ubuntu@$INSTANCE_IP:/tmp/deploy.sh
scp -o StrictHostKeyChecking=no ~/projet/docker-compose.yml ubuntu@$INSTANCE_IP:/opt/projet-site/docker-compose.yml

# Exécution du script sur l'instance
ssh -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo bash /tmp/deploy.sh"
