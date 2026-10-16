# Projet Web OCI

Ce projet gère l'infrastructure et le déploiement d'un site web sur Oracle Cloud Infrastructure (OCI) en utilisant Terraform et Docker.

## Structure du projet
- `/doc` : Documentation détaillée (architecture, exploitation, règles de l'agent).
- `/scripts` : Scripts d'automatisation (déploiement, vérification des limites, configuration).
- `/site` : Code source du site web.
- `/terraform` : Configuration de l'infrastructure (IaC).
- `/nginx` : Configuration du serveur web.

## Documentation principale
- [Documentation Générale](./doc/README.md)
- [Guide d'exploitation](./doc/exploitation.md)
- [Manuel de l'Agent DevOps](./doc/AGENT.md)

## Déploiement
Le déploiement est géré via le script `scripts/deploie.sh`. Veuillez consulter `scripts/README.md` pour les instructions d'utilisation.
