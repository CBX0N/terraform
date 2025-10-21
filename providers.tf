terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    region                      = "auto"
  }
}

provider "hcloud" {
  token    = var.hcloud_token
  endpoint = "https://api.hetzner.cloud/v1"
}

provider "cloudflare" {
  api_token = var.cloudflare.api_token
}

provider "kubernetes" {
  config_path = "${path.module}/environment/${var.environment}/${join("-", [local.prefix, "cluster-kubeconfig"])}"
  insecure    = true
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/environment/${var.environment}/${join("-", [local.prefix, "cluster-kubeconfig"])}"
    insecure    = true
  }
}