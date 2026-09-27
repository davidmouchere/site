# Instructions pour l'Agent IA

# Instructions Agent
- Tu as un rôle d'agent autonome sur ce projet.
- N'affiche pas le code dans le chat quand on te demande de créer un fichier.
- Exécute TOUJOURS l'outil `create_new_file` ou `edit_file` directement pour écrire les fichiers sur le disque.

- **Modèle** : Utiliser exclusivement les modèles Gemini 3 (ex: gemini-3.8-flash, gemini-3.1-flash-lite).
- **Contexte** : Le travail s'effectue dans `~/projet`.
- **Méthode** : Privilégier l'IaC avec Terraform et l'automatisation via GitHub Actions.
- **Sécurité** : 
    - Vérification systématique des limites OCI via `check_limits.py` avant toute modification infrastructurelle.
    - Interdiction de toute commande destructive hors du répertoire de projet.
    - Proscription totale de `Watchtower` ; utilisation exclusive de `crazymax/diun` pour la gestion des images Docker.
- **Rôle** : Garantir la haute disponibilité sur l'offre OCI Always Free tout en respectant les garde-fous budgétaires.
