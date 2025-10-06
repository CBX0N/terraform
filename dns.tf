resource "cloudflare_dns_record" "primary_server_record" {
  name    = var.cluster.k3s_san
  zone_id = var.cloudflare.dns_zone_id
  type    = "A"
  content = hcloud_server.primary_server_node.ipv4_address
  ttl     = 1
}

resource "cloudflare_dns_record" "cluster_server_record" {
  name    = var.cloudflare.domain
  zone_id = var.cloudflare.dns_zone_id
  type    = "A"
  content = hcloud_server.primary_server_node.ipv4_address
  ttl     = 1
}

resource "cloudflare_dns_record" "cluster_agents_records" {
  count   = var.cluster.agent_node_count
  name    = var.cloudflare.domain
  zone_id = var.cloudflare.dns_zone_id
  type    = "A"
  content = hcloud_server.agent_nodes[count.index].ipv4_address
  ttl     = 1
}

resource "cloudflare_dns_record" "services" {
  for_each = var.services
  name     = join(".", [each.value, var.cloudflare.domain])
  zone_id  = var.cloudflare.dns_zone_id
  type     = "CNAME"
  content  = var.cloudflare.domain
  ttl      = 1
}