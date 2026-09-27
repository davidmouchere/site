output "load_balancer_ip" {
  description = "Adresse IP publique du Load Balancer OCI"
  value       = oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address
}

output "instance_public_ips" {
  description = "Adresses IP publiques des instances web ARM"
  value       = oci_core_instance.web_instance[*].public_ip
}
