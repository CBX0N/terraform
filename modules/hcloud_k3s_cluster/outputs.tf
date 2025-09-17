output "kubeconfig" {
  value = local.kubeconfig
}
output "certificate-authority-data" {
  value = data.external.read_kubeconfig.result["certificate-authority-data"]
}
output "client-certificate-data" {
  value = data.external.read_kubeconfig.result["client-certificate-data"]
}
output "client-key-data" {
  value = data.external.read_kubeconfig.result["client-key-data"]
}
output "server" {
  value = local.kubeconfig_server
}
output "public_ipv4" {
  value = hcloud_server.server_node.ipv4_address
}