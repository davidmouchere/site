# Documentation des Scripts de Déploiement

Ce dossier contient les scripts nécessaires pour gérer le déploiement de ton site web sur tes machines virtuelles (VM) Oracle Cloud.

---

## 📂 Structure du dossier
- `deploie.sh` : Le script principal à exécuter depuis ton poste de développement (PC local).
- `README.md` : La présente documentation.

---

## 🚀 Le Script Principal : `deploie.sh`

### Ce qu'il fait :
1. **Cible tes deux VM Web** de manière automatisée (`129.151.247.30` et `82.70.230.163`) en utilisant ta clé privée Oracle (`~/.ssh/oracle`).
2. **Synchronise les fichiers** de ton site local (`/home/david/projet/site/`) vers le dossier distant des VM (`/opt/projet-site/site/`) en utilisant `rsync`.
3. **Met à jour et exécute** un script d'actualisation (`~/update_site.sh`) directement sur chaque VM pour relancer proprement les conteneurs Docker et appliquer les changements.

### Comment l'utiliser :
Ouvre un terminal sur ton PC et lance simplement la commande :

```bash
/home/david/projet/scripts/deploie.sh
```
*(Ou place-toi dans le dossier `scripts/` et tape `./deploie.sh`)*

---

## ⚙️ Configuration & Prérequis
- **Clé SSH :** Le script s'attend à trouver ta clé privée Oracle ici : `~/.ssh/oracle`.
- **Droits sur les VM :** Le dossier `/opt/projet-site` sur tes VM doit appartenir à l'utilisateur `ubuntu` pour que `rsync` puisse y écrire (si besoin, exécute `sudo chown -R ubuntu:ubuntu /opt/projet-site` une fois sur les VM).
