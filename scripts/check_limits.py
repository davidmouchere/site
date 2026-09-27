#!/usr/bin/env python3
import sys
import os
import re

def check_terraform_limits():
    tf_main_path = os.path.join("terraform", "main.tf")
    if not os.path.exists(tf_main_path):
        print(f"Erreur : Le fichier {tf_main_path} est introuvable.")
        sys.exit(1)

    with open(tf_main_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Vérification des instances ARM (VM.Standard.A1.Flex)
    # Les quotas Always Free autorisent strictement max 2 OCPU et 12 Go de RAM au total sur la location
    ocpus_matches = re.findall(r'ocpus\s*=\s*(\d+)', content)
    memory_matches = re.findall(r'memory_in_gbs\s*=\s*(\d+)', content)
    shape_matches = re.findall(r'shape\s*=\s*"([^"]+)"', content)

    # Vérification que la shape utilisée est bien ARM Ampere A1
    for shape in shape_matches:
        if "Standard.A1.Flex" not in shape and "flexible" not in shape:
            print(f"❌ ERREUR DE FACTURATION : Shape non Always Free détectée -> {shape}")
            sys.exit(1)

    total_ocpus = sum(int(x) for x in ocpus_matches)
    total_memory = sum(int(x) for x in memory_matches)

    print(f"[AUDIT ALWAYS FREE] OCPU totaux détectés : {total_ocpus} (Max gratuit : 2)")
    print(f"[AUDIT ALWAYS FREE] RAM totale détectée : {total_memory} Go (Max gratuit : 12 Go)")

    if total_ocpus > 2:
        print("❌ RISQUE DE FACTURATION : Le nombre d'OCPU dépasse la limite Always Free (2 max).")
        sys.exit(1)

    if total_memory > 12:
        print("❌ RISQUE DE FACTURATION : La quantité de RAM dépasse la limite Always Free (12 Go max).")
        sys.exit(1)

    # 2. Vérification du stockage (Disque Boot / Block Storage)
    # L'offre Always Free offre 200 Go au total (souvent répartis en 50 Go par instance max pour 4 instances, ici 2 instances de 50 Go = 100 Go)
    boot_volumes = re.findall(r'boot_volume_size_in_gbs\s*=\s*(\d+)', content)
    total_storage = sum(int(x) for x in boot_volumes)
    print(f"[AUDIT ALWAYS FREE] Stockage Boot total détecté : {total_storage} Go (Max gratuit : 200 Go)")

    if total_storage > 200:
        print("❌ RISQUE DE FACTURATION : Le stockage total dépasse les 200 Go Always Free.")
        sys.exit(1)

    # 3. Vérification du Load Balancer
    lb_bandwidth = re.findall(r'maximum_bandwidth_in_mbps\s*=\s*(\d+)', content)
    if lb_bandwidth:
        max_bw = int(lb_bandwidth[0])
        print(f"[AUDIT ALWAYS FREE] Bande passante Load Balancer : {max_bw} Mbps (Max gratuit : 10 Mbps)")
        if max_bw > 10:
            print("❌ RISQUE DE FACTURATION : La bande passante du Load Balancer dépasse 10 Mbps.")
            sys.exit(1)

    print("✅ AUDIT DE SÉCURITÉ FINANCIÈRE RÉUSSI : Tous les paramètres respectent strictement les quotas Always Free d'OCI.")
    sys.exit(0)

if __name__ == "__main__":
    check_terraform_limits()
