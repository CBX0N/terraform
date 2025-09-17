output "public_ipv4" {
  value = hcloud_server.natgw_01.ipv4_address
}
output "private_ipv4" {
  value = var.private_ip
}
output "id" {
  value = hcloud_server.natgw_01.id
}