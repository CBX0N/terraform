variable "name" {
  type = string
}
variable "location" {
  type = string
}
variable "server_type" {
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
variable "placement_group_id" {
  type    = string
  default = null
}
variable "network_cidr" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "dnat_rules" {
  type = map(object({
    ip            = string
    external_port = string
    internal_port = string
    protocol      = string
    forward       = bool
  }))
  default = {}
}
variable "cloud_init_user" {
  type = object({
    username        = string
    hashed_password = string
    ssh_key         = string
  })
}