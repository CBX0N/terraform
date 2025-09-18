variable "user_home" {
  type = string
}

variable "hcloud_token" {
  sensitive = true
}

variable "cloudflare_api_token" {
  sensitive = true
}

variable "cloudflare_dns_zone_id" {
  sensitive = true
}

variable "cloudflare_domain" {
  type = string
}

variable "cloud_init_user" {
  type = object({
    username        = string
    hashed_password = string
    ssh_key         = string
  })
}

variable "cloud_init_k3s" {
  type = object({
    k3s_url = string
    k3s_san = string
  })
}

variable "cloud_init_networking" {
  type = object({
    gateway      = string
    network_cidr = string
  })
  default = {
    gateway      = "10.0.0.1"
    network_cidr = "10.0.0.0/16"
  }
}

variable "agent_node_count" {
  type = number
}

variable "gw_dnat_rules" {
  type = map(object({
    ip            = string
    external_port = string
    internal_port = string
    protocol      = string
    forward       = bool
  }))
  default = {}
}

variable "fw_rules" {
  type = map(object({
    destination_ips = list(string)
    direction       = string
    protocol        = string
    source_ips      = list(string)
    port            = optional(string, null)
  }))
}

variable "default_labels" {
  type    = map(string)
  default = {}
}

variable "flux_gitRepository" {
  type = string
}

variable "cluster_dns_name" {
  type = string
}

variable "firewalled_services" {
  type = set(string)
}