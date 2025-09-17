locals {
  k3s_url           = "https://${var.private_ip}:6443"
  cloud_init_config = merge(var.cloud_init_user, { gateway = var.gateway_ip }, { cluster_token = random_string.cluster_join_token.result }, { k3s_url = local.k3s_url }, { k3s_san = var.dns_name }, { server_ip = var.private_ip })
  ip_split          = split(".", var.private_ip)
  ip_prefix         = join(".", [local.ip_split[0], local.ip_split[1], local.ip_split[2]])
  kubeconfig        = replace(data.external.read_kubeconfig.result.filecontent, "127.0.0.1", var.dns_name)
  kubeconfig_server = replace(data.external.read_kubeconfig.result.server, "127.0.0.1", var.dns_name)
}