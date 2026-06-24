variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean Region"
  type        = string
  default     = "fra1" # frankfurt. germany
}

variable "droplet_size" {
  description = "Size of the Droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "droplet_image" {
  description = "Droplet image (OS)"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "base_domain" {
  description = "The root domain managed in DigitalOcean"
  type        = string
  default     = "ksohail.space"
}

variable "subdomain" {
  description = "The specific A record to create"
  type        = string
  default     = "@"
}

variable "vm_name" {
  description = "The name of the Droplet"
  type        = string
}

variable "ssh_name" {
  description = "The name of the SSH key in DigitalOcean"
  type        = string
}

variable "project_name" {
  description = "The name of the DigitalOcean project to assign resources to"
  type        = string
}
