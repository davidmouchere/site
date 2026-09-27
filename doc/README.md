# Infrastructure Haute Disponibilité sur Oracle Cloud Infrastructure (OCI) - Always Free

Ce projet fournit une architecture Terraform complète et automatisée pour déployer une infrastructure web à haute disponibilité s'inscrivant strictement dans le cadre des quotas **Always Free** d'Oracle Cloud Infrastructure (OCI).

## Architecture

- **Compute (Instances ARM)** : 2 instances Ampere ARM64 (`VM.Standard.A1.Flex`) configurées avec 1 OCPU et 6 Go de RAM chacune.
- **Répartition de charge** : 1 OCI Load Balancer flexible (bridé à 10 Mbps).
- **Stockage** : 50 Go de disque boot par instance.
- **Conteneurisation** : Docker & Docker Compose sur les instances, avec surveillance des mises à jour des images via **DIUN** (remplacement de Watchtower).
- **Sécurité** : Pare-feu configuré, Fail2ban intégré via `cloud-init`, et gestion stricte des secrets via les variables Terraform et GitHub Actions Secrets.

---

## Arborescence du Projet

```text
.
├── .gitignore
├── README.md
├── AGENT.md
├── RULES.md
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docker/
│   └── docker-compose.yml
├── scripts/
│   ├── check_limits.py
│   └── cloud-init.sh
└── terraform/
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── terraform.tfvars.example
```

---

## Prérequis

1. Un compte Oracle Cloud Infrastructure (OCI) avec les quotas Always Free disponibles.
2. Une paire de clés SSH pour l'accès aux instances.
3. Un compte GitHub pour l'intégration CI/CD.

---

## Déploiement Manuel via Terraform

1. Se placer dans le répertoire Terraform :
   ```bash
   cd terraform/
   ```
2. Copier et renseigner le fichier de configuration des variables :
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Initialiser et appliquer la configuration :
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
