terraform {
  required_version = ">= 1.6.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Récupération de la liste des Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Récupération de l'image Ubuntu ARM Always Free la plus récente
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "main_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "always-free-vcn"
  dns_label      = "freevcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "main_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "always-free-igw"
}

# Route Table
resource "oci_core_route_table" "main_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "always-free-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main_igw.id
  }
}

# Subnet Public
resource "oci_core_subnet" "public_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main_vcn.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "always-free-public-subnet"
  dns_label      = "subnet"
  route_table_id = oci_core_route_table.main_rt.id
  security_list_ids = [oci_core_security_list.public_sl.id]
}

# Security List Sécurisée (Principe du moindre privilège)
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "always-free-sl"

  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.admin_ssh_cidr
    tcp_options {
      min = 22
      max = 22
    }
    description = "SSH Administration restreinte"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
    description = "HTTP Web Traffic"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
    description = "HTTPS Web Traffic"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic for updates and dependencies"
  }
}

# Instances Compute ARM (2 instances - 1 OCPU et 6 Go de RAM chacune pour respecter les quotas Always Free totaux de 2 OCPU / 12 Go)
resource "oci_core_instance" "web_instance" {
  count               = 2
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index % length(data.oci_identity_availability_domains.ads.availability_domains)].name
  display_name        = "web-server-${count.index + 1}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("../scripts/cloud-init.sh"))
  }
}

# Load Balancer Flexible Sécurisé
resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id = var.compartment_id
  display_name   = "always-free-secure-lb"
  shape          = "flexible"
  subnet_ids     = [oci_core_subnet.public_subnet.id]

  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
}

resource "oci_load_balancer_backend_set" "lb_backend_set" {
  name             = "web-backend-set"
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol            = "HTTP"
    port                = 80
    url_path            = "/"
    return_code         = 200
    interval_ms         = 10000
    timeout_in_millis   = 3000
    retries             = 3
  }
}

resource "oci_load_balancer_backend" "lb_backends" {
  count            = 2
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.lb_backend_set.name
  ip_address       = oci_core_instance.web_instance[count.index].private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

# Listener HTTP (Port 80)
resource "oci_load_balancer_listener" "lb_listener_http" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "web-listener-http"
  default_backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
  protocol                 = "HTTP"
  port                     = 80
}
