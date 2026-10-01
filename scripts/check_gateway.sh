#!/bin/bash

URL="http://79.72.27.8/"
TERRAFORM_DIR="/home/david/projet/terraform"

while true; do
    echo "[$(date)] Vérification de l'état de $URL..."
    
    # Récupération du code HTTP de la page
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    
    echo "[$(date)] Code HTTP reçu : $HTTP_STATUS"
    
    # Si on détecte une Bad Gateway (502) ou une erreur serveur 5xx
    if [[ "$HTTP_STATUS" =~ ^5[0-9]{2}$ ]]; then
        echo "[$(date)] Alerte : Erreur $HTTP_STATUS détectée ! Lancement de terraform apply..."
        
        cd "$TERRAFORM_DIR" || exit 1
        terraform apply -auto-approve
        
        echo "[$(date)] Terraform apply terminé. Nouvelle tentative dans 30 secondes..."
    else
        echo "[$(date)] Le site répond correctement (HTTP $HTTP_STATUS). Arrêt du script."
        break
    fi
    
    # Attente de 30 secondes avant la prochaine vérification
    sleep 30
done
