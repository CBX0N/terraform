resource "hcloud_network" "main" {
  name     = join("-", [local.prefix, "net-01"])
  ip_range = var.network.ip_range
}

resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = var.network.subnet.type
  network_zone = var.network.subnet.network_zone
  ip_range     = var.network.subnet.ip_range
}

resource "hcloud_placement_group" "main" {
  name   = join("-", [local.prefix, "placement-group"])
  labels = local.tags
  type   = "spread"
}

resource "tls_private_key" "cluster" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "cluster" {
  name       = join("-", [local.prefix, "cluster-ssh-key"])
  public_key = tls_private_key.cluster.public_key_openssh
}

resource "hcloud_server" "primary_server_node" {
  name               = join("-", [local.prefix, "k3s-primary"])
  image              = var.cluster.image
  server_type        = var.cluster.server_node_type
  location           = var.location
  labels             = merge(local.tags, { join("-", [local.prefix, "firewall"]) = true })
  placement_group_id = hcloud_placement_group.main.id
  ssh_keys           = [hcloud_ssh_key.cluster.id]
  user_data          = local.user_data_server

  network {
    network_id = hcloud_network.main.id
    ip         = var.cluster.primary_server_ip
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "hcloud_server" "agent_nodes" {
  depends_on         = [hcloud_server.primary_server_node]
  count              = var.cluster.agent_node_count
  name               = join("-", [local.prefix, "k3s-node", count.index])
  image              = var.cluster.image
  server_type        = var.cluster.agent_node_type
  location           = var.location
  labels             = merge(local.tags, { join("-", [local.prefix, "firewall"]) = true })
  placement_group_id = hcloud_placement_group.main.id
  ssh_keys           = [hcloud_ssh_key.cluster.id]
  user_data          = local.user_data_agent

  network {
    network_id = hcloud_network.main.id
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  lifecycle {
    ignore_changes       = [ssh_keys, network]
    replace_triggered_by = [hcloud_server.primary_server_node.id]
  }
}

resource "hcloud_firewall" "main" {
  name = join("-", [local.prefix, "firewall"])
  apply_to {
    label_selector = join("-", [local.prefix, "firewall"])
  }

  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      description     = rule.value["description"]
      destination_ips = rule.value["destination_ips"]
      direction       = rule.value["direction"]
      port            = rule.value["port"]
      protocol        = rule.value["protocol"]
      source_ips      = rule.value["source_ips"]
    }
  }
}

