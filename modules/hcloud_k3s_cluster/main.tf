resource "random_string" "cluster_join_token" {
  numeric = false
  special = false
  upper   = false
  length  = 25
}

resource "hcloud_server" "server_node" {
  name        = "${var.location}-k3s-01"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  network {
    network_id = var.network_id
    ip         = var.private_ip
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  user_data                = templatefile("${path.module}/cloud-init-server.tfpl", local.cloud_init_config)
  placement_group_id       = var.placement_group_id
  shutdown_before_deletion = true
  labels                   = var.tags
}

resource "random_string" "agent_name" {
  count   = var.agent_node_count
  numeric = false
  special = false
  upper   = false
  length  = 5
}

resource "hcloud_server" "agent_nodes" {
  depends_on  = [hcloud_server.server_node]
  count       = var.agent_node_count
  name        = join("-", ["${var.location}-k3a", random_string.agent_name[count.index].result])
  image       = var.image
  server_type = var.agent_type
  location    = var.location
  network {
    network_id = var.network_id
    ip         = "${local.ip_prefix}.${10 + count.index}"
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  user_data                = templatefile("${path.module}/cloud-init-agent.tfpl", local.cloud_init_config)
  placement_group_id       = var.placement_group_id
  shutdown_before_deletion = true
  labels                   = var.tags
}

data "external" "read_kubeconfig" {
  program = ["bash", "${path.module}/read_remote_file.sh"]

  query = {
    "host"     = hcloud_server.server_node.ipv4_address
    "username" = var.cloud_init_user.username
    "filepath" = "/etc/rancher/k3s/k3s.yaml"
    "keypath"  = "~/.ssh/id_ed25519"
    "port"     = "22"
  }
  depends_on = [hcloud_server.server_node]
}