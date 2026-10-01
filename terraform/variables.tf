variable "tenancy_ocid" {
  description = "OCID de la location (Tenancy) OCI"
  type        = string
}

variable "user_ocid" {
  description = "OCID de l'utilisateur OCI"
  type        = string
}

variable "fingerprint" {
  description = "Empreinte (fingerprint) de la clé API OCI"
  type        = string
}

variable "private_key_path" {
  description = "Chemin absolu ou relatif vers la clé privée API OCI"
  type        = string
}

variable "region" {
  description = "Région OCI cible (ex: eu-marseille-1)"
  type        = string
  default     = "eu-marseille-1"
}

variable "compartment_id" {
  description = "OCID du compartiment OCI"
  type        = string
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour la connexion aux instances"
  type        = string
}

variable "admin_ssh_cidr" {
  description = "Adresse IP ou bloc CIDR autorisé pour la connexion SSH (ex: votre_ip/32 ou 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "domain_name" {
  description = "Nom de domaine ou sous-domaine (laisser vide si non configuré)"
  type        = string
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email pour l'enregistrement du certificat Let's Encrypt (laisser vide si non configuré)"
  type        = string
  default     = ""
}
