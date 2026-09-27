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
  description = "Région OCI cible (ex: eu-frankfurt-1)"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "compartment_id" {
  description = "OCID du compartiment OCI"
  type        = string
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour la connexion aux instances"
  type        = string
}
