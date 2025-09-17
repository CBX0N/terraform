resource "hcloud_server" "natgw_01" {
  name        = var.name
  location    = var.location
  server_type = var.server_type
  image       = var.image
  network {
    network_id = var.network_id
    ip         = var.private_ip
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data                = templatefile("${path.module}/cloud-init.tfpl", local.cloud_init_config)
  placement_group_id       = var.placement_group_id
  labels                   = var.tags
  shutdown_before_deletion = true
}

resource "hcloud_network_route" "nat_gateway" {
  network_id  = var.network_id
  destination = "0.0.0.0/0"
  gateway     = var.private_ip
  depends_on  = [hcloud_server.natgw_01]
}