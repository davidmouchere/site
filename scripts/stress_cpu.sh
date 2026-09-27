#!/bin/bash

DURATION=60
echo "=== Démarrage du stress test CPU pour une durée de ${DURATION} secondes ==="

# Lancement d'un stress CPU en arrière-plan sur tous les cœurs disponibles
# On utilise une boucle infinie de calcul mathématique (scale=10000; 4*a(1)) via bc ou une simple boucle while
# Pour être indépendant et robuste, on lance des processus de calcul en arrière-plan

CORES=$(nproc)
echo "Utilisation de ${CORES} cœurs pour le stress test."

PIDS=()
for ((i=1; i<=CORES; i++)); do
    # Boucle CPU intensive en arrière-plan
    python3 -c "while True: pass" &
    PIDS+=($!)
done

# Attente de la durée spécifiée
sleep $DURATION

echo "=== Fin de la période de stress, arrêt des processus ==="

# Arrêt propre de tous les processus lancés
for pid in "${PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
    fi
done

# Petite pause pour laisser le système nettoyer
sleep 2

# CONTRÔLE DE SÉCURITÉ : Vérification qu'aucun processus python résiduel ne tourne en boucle
echo "=== Contrôle d'extinction ==="
RESIDUAL=$(ps aux | grep "[p]ython3 -c while True: pass" | wc -l)

if [ "$RESIDUAL" -gt 0 ]; then
    echo "⚠️ ATTENTION : Des processus de stress tournent encore. Forçage de l'arrêt..."
    pkill -9 -f "python3 -c while True: pass"
    sleep 1
    RESIDUAL_AFTER=$(ps aux | grep "[p]ython3 -c while True: pass" | wc -l)
    if [ "$RESIDUAL_AFTER" -eq 0 ]; then
        echo "✅ Tous les processus ont été arrêtés avec succès après forçage."
    else
        echo "❌ ERREUR CRITIQUE : Certains processus résiduels persistent !"
        exit 1
    fi
else
    echo "✅ CONTRÔLE OK : Tous les processus de stress ont été éteints proprement et aucun résidu n'a été détecté."
fi
