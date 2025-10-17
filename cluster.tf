resource "local_sensitive_file" "ssh_key" {
  filename        = "${path.module}/${join("-", [local.prefix, "cluster-ssh-key"])}"
  content         = tls_private_key.cluster.private_key_openssh
  file_permission = "0600"
}

data "external" "kubeconfig" {
  depends_on = [hcloud_server.primary_server_node, hcloud_firewall.main]
  program    = ["bash", "${path.module}/read_kubeconfig.sh"]

  query = {
    host        = hcloud_server.primary_server_node.ipv4_address
    username    = "root"
    port        = "22"
    keypath     = local_sensitive_file.ssh_key.filename
    cluster_san = var.cluster.k3s_san
  }
}

resource "local_sensitive_file" "kubeconfig" {
  depends_on      = [data.external.kubeconfig]
  filename        = "${path.module}/${join("-", [local.prefix, "cluster-kubeconfig"])}"
  content         = data.external.kubeconfig.result["kubeconfig"]
  file_permission = "0600"
  lifecycle {
    ignore_changes = [content]
  }
}

resource "kubernetes_secret" "hcloud_token" {
  depends_on = [data.external.kubeconfig]
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }
  data = {
    "token"   = var.hcloud_token
    "network" = hcloud_network.main.name
  }
}

resource "helm_release" "hccm" {
  depends_on      = [kubernetes_secret.hcloud_token]
  name            = "hccm"
  repository      = "https://charts.hetzner.cloud"
  chart           = "hcloud-cloud-controller-manager"
  namespace       = "kube-system"
  cleanup_on_fail = true
  set = [
    {
      name  = "networking.enabled"
      value = true
    },
    {
      name  = "networking.clusterCIDR"
      value = "10.42.0.0/16"
  }]
}

resource "helm_release" "flux" {
  depends_on       = [helm_release.hccm]
  name             = "flux"
  namespace        = "flux-system"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  create_namespace = true
  cleanup_on_fail  = true
}

resource "helm_release" "flux_sync" {
  depends_on       = [helm_release.flux]
  name             = "flux-sync"
  namespace        = helm_release.flux.namespace
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2-sync"
  create_namespace = true
  cleanup_on_fail  = true
  values = [
    yamlencode({
      gitRepository = {
        spec = {
          url = var.flux.git_repository
          secretRef = {
            name = "flux-system"
          }
          interval = "1m0s"
          ref = {
            branch = var.flux.repo_tag
          }
        }
      }
      kustomization = {
        spec = {
          interval = "30s"
          path     = var.flux.path
          prune    = true
        }
      }
    })
  ]
}

data "cloudflare_dns_records" "name" {
  zone_id = var.cloudflare.dns_zone_id
  name = {
    exact = var.cloudflare.domain
  }
  type = "A"
}

resource "local_file" "metallb_ipaddresspool" {
  filename = "${path.module}/${join("-", [local.prefix, "ipaddresspool.json"])}"
  content = jsonencode({
    "apiVersion" = "metallb.io/v1beta1"
    "kind"       = "IPAddressPool"
    "metadata" = {
      "name"      = "pool"
      "namespace" = "metallb-system"
    }
    "spec" = { "addresses" = [for record in data.cloudflare_dns_records.name.result : "${record.content}/32"] }
    }
  )
}

resource "local_file" "metallb_l2advertisement" {
  filename = "${path.module}/${join("-", [local.prefix, "metallb-l2advertisement.json"])}"
  content = jsonencode({
    "apiVersion" = "metallb.io/v1beta1"
    "kind"       = "L2Advertisement"
    "metadata" = {
      "name"      = "l2-advertisement"
      "namespace" = "metallb-system"
    }
    "spec" = { "ipAddressPools" = ["pool"] }
    }
  )
}

resource "helm_release" "metallb" {
  depends_on = [data.external.kubeconfig]
  name             = "metallb"
  namespace        = "metallb-system"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  create_namespace = true
  cleanup_on_fail  = true

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${local_sensitive_file.kubeconfig.filename} -f ${local_file.metallb_ipaddresspool.filename}"
    when    = create
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${local_sensitive_file.kubeconfig.filename} -f ${local_file.metallb_l2advertisement.filename}"
    when    = create
  }

  lifecycle {
    replace_triggered_by = [local_file.metallb_ipaddresspool, local_file.metallb_l2advertisement]
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
    api-token = var.cloudflare.api_token
  }
}