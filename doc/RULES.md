# Règles et Directives de Sécurité (RULES.md)

Ce document formalise les règles impératives applicables au projet et à tout agent ou opérateur manipulant ce dépôt.

## 1. Sécurité du Système Hôte
- **Interdiction stricte des commandes destructives** : Toute commande potentiellement destructive (`rm -rf`, suppression de paquets système, modification de fichiers hors du répertoire racine du projet) est formellement interdite.
- **Isolation du périmètre** : Sauf si l'action est strictement restreinte et contenue dans le dossier utilisateur `~/projet`, aucune modification système globale ne doit être tentée.

## 2. Choix des Composants et Outils Docker
- **Proscription de Watchtower** : L'utilisation de l'outil Watchtower est strictement proscrite en raison de son statut non maintenu et des risques de sécurité associés.
- **Utilisation obligatoire de DIUN** : Pour le suivi et la notification des mises à jour d'images Docker, l'utilisation de **DIUN (`crazymax/diun`)** est obligatoire.

## 3. Intégration IA & SDK Gemini
- **Modèles Gemini à jour** : Pour tout script Python ou intégration d'API faisant appel à Gemini (ex: scripts d'analyse ou d'assistance), l'utilisation des modèles de la famille **Gemini 3** (ex: `gemini-3.8-flash` ou `gemini-3.1-flash-lite`) est obligatoire, conformément aux dernières spécifications de l'API Google.

## 4. Quotas OCI Always Free
- Le respect absolu des limites Always Free d'Oracle Cloud Infrastructure est une règle non négociable pour éviter tout coût inattendu.
