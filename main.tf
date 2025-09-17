resource "hcloud_placement_group" "placement_a" {
  name   = "placement-A"
  type   = "spread"
  labels = var.default_labels
}

resource "hcloud_network" "net_01" {
  name     = "net-01"
  ip_range = "10.0.0.0/16"
  labels   = var.default_labels
}

resource "hcloud_network_subnet" "snet_01" {
  network_id   = hcloud_network.net_01.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_firewall" "fw01" {
  name = "fw-01"
  dynamic "rule" {
    for_each = var.fw_rules
    content {
      destination_ips = rule.value.destination_ips
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      source_ips      = rule.value.source_ips
      port            = rule.value.port
    }
  }
  apply_to {
    label_selector = "firewall"
  }
  labels = var.default_labels
}

module "k3s_cluster" {
  depends_on         = [hcloud_network_subnet.snet_01]
  source             = "./modules/hcloud_k3s_cluster"
  image              = "ubuntu-24.04"
  server_type        = "cax11"
  agent_type         = "cax11"
  location           = "fsn1"
  private_ip         = "10.0.0.4"
  agent_node_count   = var.agent_node_count
  dns_name           = var.cluster_dns_name
  gateway_ip         = "10.0.0.1"
  cloud_init_user    = var.cloud_init_user
  tags               = merge(var.default_labels, { firewall = true })
  network_id         = hcloud_network.net_01.id
  placement_group_id = hcloud_placement_group.placement_a.id
}

resource "local_file" "kubeconfig" {
  filename        = "${var.user_home}/.kube/config"
  content         = module.k3s_cluster.kubeconfig
  file_permission = "0600"
}

resource "local_file" "certificate_authority_data" {
  filename        = "${var.user_home}/.kube/ca.crt"
  content         = module.k3s_cluster.certificate-authority-data
  file_permission = "0600"
}

resource "local_file" "client_key_data" {
  filename        = "${var.user_home}/.kube/client.key"
  content         = module.k3s_cluster.client-key-data
  file_permission = "0600"
}

resource "local_file" "client_certificate_data" {
  filename        = "${var.user_home}/.kube/client.crt"
  content         = module.k3s_cluster.client-certificate-data
  file_permission = "0600"
}