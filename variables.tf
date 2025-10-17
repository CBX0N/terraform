variable "hcloud_token" {
  type = string
}

variable "cloudflare" {
  type = object({
    api_token   = string
    dns_zone_id = string
    domain      = string
  })
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "network" {
  type = object({
    ip_range = string
    subnet = object({
      ip_range     = string
      type         = string
      network_zone = string
    })
  })
}

variable "cluster" {
  type = object({
    image                = string
    server_node_type     = string
    agent_node_type      = string
    agent_node_count     = string
    primary_server_ip    = string
    username             = string
    user_hashed_password = string
    k3s_san              = string
  })
}

variable "services" {
  type = set(string)
}

variable "firewall_rules" {
  type = map(object({
    description     = string
    destination_ips = optional(set(string), [])
    direction       = string
    port            = optional(string, "any")
    protocol        = string
    source_ips      = optional(set(string), [])
  }))
}

variable "flux" {
  type = object({
    git_repository = string
    repo_tag       = string
    path           = string
  })
}