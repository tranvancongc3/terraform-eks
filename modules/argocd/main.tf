resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = var.repository
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true

  # Ensure stable installation
  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  force_update    = true

  # Default values: install CRDs, no ingress/domain configuration
  values = [
    yamlencode(merge({
      installCRDs = true
    }, var.values))
  ]
}