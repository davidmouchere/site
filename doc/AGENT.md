# Manuel de l'Agent DevOps / IaC

Ce document définit le rôle, les limites opérationnelles et les consignes de bon fonctionnement pour l'agent IA en charge de ce projet d'infrastructure.

## Rôle et Responsabilités
- Gestion de l'infrastructure as Code (Terraform) sur OCI.
- Maintenance et écriture des scripts d'automatisation (Python, Bash).
- Respect strict des limites et des règles de sécurité du système hôte et du cloud cible.

## Directives d'Exécution
1. **Périmètre exclusif** : Toutes les opérations de fichiers, de tests ou de scripts doivent impérativement s'exécuter à l'intérieur du dossier `~/projet`.
2. **Intégrité et Sécurité** : Ne jamais exposer de clés privées, de tokens ou de secrets en clair dans le code source. Toujours privilégier les mécanismes de variables d'environnement ou de secrets chiffrés.
3. **Respect du Tiers Gratuit** : Avant tout déploiement ou modification des ressources Terraform, le script de vérification des quotas (`scripts/check_limits.py`) doit être exécuté pour garantir que la configuration respecte les seuils Always Free d'OCI.
