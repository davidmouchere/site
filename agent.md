# Documentation de Déploiement Automatisé

Ce projet utilise Terraform et Cloud-init pour déployer des instances Oracle Cloud (ARM) configurées automatiquement.

## Architecture de Déploiement
Le déploiement est désormais géré par un service système (`systemd`) pour garantir la robustesse face aux timeouts de `cloud-init`.

### Flux d'exécution :
1. **Terraform** : Déploie les instances et injecte le script `cloud-init.sh` via `user_data`.
2. **Cloud-init** : 
   - Crée le script de configuration `/opt/projet-site/setup.sh`.
   - Enregistre et active le service `setup-site.service`.
3. **Service `setup-site`** :
   - S'exécute automatiquement au démarrage (après 60s pour stabiliser le réseau).
   - Installe Docker, Git, Python3-venv.
   - Clone le dépôt du site.
   - Installe Certbot dans un environnement virtuel (`/opt/certbot/`).
   - Démarre les conteneurs Docker en mode HTTP.
   - Génère le certificat SSL via DuckDNS.
   - Bascule la configuration Nginx en HTTPS et redémarre le reverse-proxy.

## Fichiers Clés
- `terraform/main.tf` : Définit l'infrastructure OCI. Utilise `${path.module}/../scripts/cloud-init.sh` pour pointer vers le script de configuration.
- `scripts/cloud-init.sh` : Script d'amorçage qui installe le service de déploiement.
- `/opt/projet-site/setup.sh` : Script de configuration réelle (généré sur l'instance).

## Dépannage
Si le déploiement semble bloqué ou incomplet, connectez-vous en SSH à l'instance et vérifiez les logs du service :

```bash
# Vérifier l'état du service de déploiement
sudo systemctl status setup-site

# Voir les logs en temps réel
sudo journalctl -u setup-site -f

# Vérifier les logs de Certbot
sudo cat /var/log/deploy-ssl.log
```

## Maintenance
- **Renouvellement SSL** : Automatisé via `crontab` (configuré dans `setup.sh`).
- **Mise à jour du site** : Le service `diun` (Docker Image Update Notifier) est configuré pour surveiller les mises à jour des images Docker automatiquement.
