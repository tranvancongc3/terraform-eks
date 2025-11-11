output "release_name" {
  description = "Helm release name of Argo CD"
  value       = helm_release.argocd.name
}

output "namespace" {
  description = "Argo CD namespace"
  value       = helm_release.argocd.namespace
}