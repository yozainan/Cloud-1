# define the provider
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# reference to SSH key 
data "digitalocean_ssh_key" "my_key" {
  name = var.ssh_name
}

# reference a project
data "digitalocean_project" "my_project" {
  name = var.project_name
}

# reference the domain to get its ID
resource "digitalocean_domain" "main" {
  name = var.base_domain
}

# create the A record for the droplet's IP address
resource "digitalocean_record" "dynamic_record" {
  domain = digitalocean_domain.main.id
  type   = "A"
  name   = var.subdomain 
  value  = digitalocean_droplet.cloud_1_vm.ipv4_address
  ttl    = 1800
}

# create the droplet
resource "digitalocean_droplet" "cloud_1_vm" {
  image    = "ubuntu-22-04-x64"
  name     = var.vm_name
  region   = var.region
  size     = var.droplet_size
  ssh_keys = [data.digitalocean_ssh_key.my_key.id]
}

# assign droplet to the project
resource "digitalocean_project_resources" "cloud_1" {
  project = data.digitalocean_project.my_project.id
  resources = [
    digitalocean_droplet.cloud_1_vm.urn
  ]
}

# firewall to lock down the server ONLY ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) are allowed
resource "digitalocean_firewall" "cloud_1_firewall" {
  name = "web-traffic-${var.vm_name}"
  droplet_ids = [digitalocean_droplet.cloud_1_vm.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "server_public_ip" {
  value = digitalocean_droplet.cloud_1_vm.ipv4_address
}
