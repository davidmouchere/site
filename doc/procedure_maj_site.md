# Procédure de mise à jour du site web sur OCI (Sans recréer les instances)

Cette procédure permet de mettre à jour le contenu du site web directement sur les serveurs de production Oracle Cloud Infrastructure (OCI) sans passer par Terraform, évitant ainsi les erreurs de type `Out of capacity` (erreur 500).

## Contexte
Le script d'initialisation (`cloud-init`) ne s'exécutant qu'à la création initiale de la machine virtuelle, toute modification des fichiers du site (`index.html`, `tarifs.html`, images, etc.) doit être poussée directement sur les serveurs actifs.

---

## Étapes de mise à jour

### 1. Récupérer les adresses IP publiques des instances ARM
Depuis votre poste de travail, dans le dossier du projet Terraform, affichez les IP des serveurs :
```bash
terraform -chdir=projet/terraform output instance_public_ips
```

### 2. Se connecter en SSH à la première instance
```bash
ssh ubuntu@<IP_DE_L_INSTANCE_1>
```

### 3. Mettre à jour le code source et relancer le conteneur Nginx
Une fois connecté sur le serveur, exécutez les commandes suivantes :
```bash
cd /opt/projet-site
rm -rf repo-temp site
git clone https://github.com/davidmouchere/site.git repo-temp
cp -r repo-temp/site site
rm -rf repo-temp
docker compose restart web
```

### 4. Répéter l'opération pour la deuxième instance
Déconnectez-vous (`exit`) puis répétez les étapes 2 et 3 pour la seconde instance (`<IP_DE_L_INSTANCE_2>`).

---
*Vos modifications sont désormais en ligne de manière instantanée et sécurisée.*
