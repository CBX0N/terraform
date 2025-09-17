variable "location" {
  type = string
}
variable "server_type" {
  type = string
}
variable "agent_type" {
  type = string
}
variable "image" {
  type    = string
  default = "ubuntu-24.04"
}
variable "network_id" {
  type = string
}
variable "private_ip" {
  type = string
}
variable "gateway_ip" {
  type = string
}
variable "placement_group_id" {
  type    = string
  default = null
}
variable "dns_name" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "cloud_init_user" {
  type = object({
    username        = string
    hashed_password = string
    ssh_key         = string
  })
}
variable "agent_node_count" {
  type = number
}