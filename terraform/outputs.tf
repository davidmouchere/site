output "instance_public_ip" {
  description = "Adresse IP publique de l'instance web"
  value       = oci_core_instance.web_instance.public_ip
}
