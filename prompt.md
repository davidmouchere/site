Tu es un expert DevOps et Infrastructure as Code (IaC). Je souhaite générer l'ensemble des fichiers nécessaires pour déployer une infrastructure web à haute disponibilité sur l'offre Always Free d'Oracle Cloud Infrastructure (OCI).

Génère le code complet pour les fichiers suivants en respectant strictly l'arborescence du projet :

Arborescence attendue :
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

Contraintes et directives strictes :

1. Périmètre de travail & Isolation :
   - Tout le projet et l'intégralité des opérations doivent se dérouler exclusivement dans le dossier ~/projet.

2. Directives dans RULES.md :
   - Ajouter l'interdiction stricte et le refus de toute commande destructive sur l'ensemble du système hôte (ex: rm -rf, suppression de paquets système, modification de fichiers hors du répertoire racine du projet), sauf si l'action est strictement restreinte au dossier ~/projet.
   - Proscrire Watchtower (projet non maintenu) et imposer DIUN (crazymax/diun) pour le suivi des images Docker.

3. Configuration SDK / Modèle Gemini :
   - Pour tout script Python ou intégration d'API Gemini (ex: ask_gemini.py), utiliser exclusivement les modèles à jour Gemini 3 (ex: gemini-3.8-flash ou gemini-3.1-flash-lite) conformément aux dernières spécifications de l'API Google.

4. Respect du Tier Gratuit OCI (Always Free - 0 €) :
   - Compute : 2 VM Ampere ARM64 (VM.Standard.A1.Flex) avec 1 OCPU et 6 Go de RAM chacune (total : 2 OCPU, 12 Go RAM).
   - Load Balancer : 1 Load Balancer flexible bridé à 10 Mbps max.
   - Stockage : 50 Go par VM (total < 200 Go).

5. Sécurité :
   - Aucun secret ni clé API en dur. Utiliser les variables Terraform et les GitHub Action Secrets.
   - Configuration de Fail2ban et règles d'iptables/netfilter dans cloud-init.sh.

6. CI/CD & Garde-fous :
   - Le script Python `scripts/check_limits.py` doit parser `terraform/main.tf` et vérifier que les limites gratuites ne sont pas dépassées.
   - Le workflow GitHub Actions (`deploy.yml`) doit exécuter `check_limits.py` AVANT toute commande Terraform (`init`, `plan`, `apply`).

Pour chaque fichier, fournis le chemin complet et le contenu exhaustif (sans omission ni commentaires "TODO").