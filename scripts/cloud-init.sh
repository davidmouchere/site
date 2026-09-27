#!/bin/bash
# Script cloud-init pour la configuration initiale des instances OCI Always Free

export DEBIAN_FRONTEND=noninteractive

# Mise à jour du système
apt-get update && apt-get upgrade -y

# Installation des dépendances de base
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release ufw fail2ban

# Configuration de Fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Installation de Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Activation et démarrage de Docker
systemctl enable docker
systemctl start docker

# Configuration du pare-feu UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

echo "Configuration cloud-init terminée avec succès."
