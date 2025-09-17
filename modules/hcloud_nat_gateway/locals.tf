locals {
  cloud_init_config = merge(var.cloud_init_user, { dnat_rules = var.dnat_rules }, { network_cidr = var.network_cidr })
}