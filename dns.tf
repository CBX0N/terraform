resource "cloudflare_dns_record" "server_record" {
  name    = var.cluster_dns_name
  zone_id = var.cloudflare_dns_zone_id
  type    = "A"
  content = module.k3s_cluster.public_ipv4
  ttl     = 1
}

resource "cloudflare_dns_record" "firewalled_services" {
  for_each = var.firewalled_services
  name     = join(".", [each.value, var.cloudflare_domain])
  zone_id  = var.cloudflare_dns_zone_id
  type     = "CNAME"
  content  = cloudflare_dns_record.server_record.name
  ttl      = 1
}

data "hcloud_load_balancers" "loadbalancers" {}

locals {
  loadbalancers = contains(data.hcloud_load_balancers.loadbalancers.load_balancers[*].name, "fsn1-lb-01")
}

resource "cloudflare_dns_record" "cluster_record" {
  count   = local.loadbalancers ? 1 : 0
  name    = var.cloudflare_domain
  zone_id = var.cloudflare_dns_zone_id
  type    = "A"
  content = one([
    for lb in data.hcloud_load_balancers.loadbalancers.load_balancers : lb.ipv4
    if lb.name == "fsn1-lb-01"
  ])
  ttl = 1
}

resource "cloudflare_dns_record" "jellyfin" {
  count   = local.loadbalancers ? 1 : 0
  name    = join(".", ["jellyfin", var.cloudflare_domain])
  zone_id = var.cloudflare_dns_zone_id
  type    = "CNAME"
  content = cloudflare_dns_record.cluster_record[0].name
  ttl     = 1
}

resource "cloudflare_dns_record" "jellyseerr" {
  count   = local.loadbalancers ? 1 : 0
  name    = join(".", ["jellyseerr", var.cloudflare_domain])
  zone_id = var.cloudflare_dns_zone_id
  type    = "CNAME"
  content = cloudflare_dns_record.cluster_record[0].name
  ttl     = 1
}
