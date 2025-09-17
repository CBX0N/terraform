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
          url = var.flux_gitRepository
          secretRef = {
            name = "flux-system"
          }
          interval = "1m0s"
          ref = {
            branch = "main"
          }
        }
      }
      kustomization = {
        spec = {
          interval = "30s"
          path     = "./flux/kustomizations/"
          prune    = true
        }
      }
    })
  ]
}
