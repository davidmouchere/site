#!/usr/bin/env bash

# Utilise 'codium' ou 'vscodium' selon le binaire présent sur votre système
CLI_CMD=$(command -v codium || command -v vscodium || command -v vscodium-oss)

if [ -z "$CLI_CMD" ]; then
    echo "Erreur : Commande VSCodium non trouvée."
    exit 1
fi

grep -v '^#' requirements-extensions.txt | grep -v '^[[:space:]]*$' | while read -r extension; do
    echo "Installation de $extension..."
    $CLI_CMD --install-extension "$extension"
done
