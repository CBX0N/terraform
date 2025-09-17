resource "kubernetes_secret" "hcloud_token" {
  depends_on = [local_file.kubeconfig]
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }
  data = {
    "token"   = var.hcloud_token
    "network" = hcloud_network.net_01.name
  }
}

resource "kubernetes_secret" "flux_ssh_key" {
  metadata {
    name      = "flux-system"
    namespace = helm_release.flux.namespace
  }
  data = {
    "identity"     = file("~/.ssh/flux")
    "identity.pub" = file("~/.ssh/flux.pub")
    "known_hosts"  = "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_secret" "cloudflare_api_key" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }
  data = {
    api-token = var.cloudflare_api_token
  }
}