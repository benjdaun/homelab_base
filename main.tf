resource "helm_release" "argo_cd" {
  name       = "argocd"
  namespace  = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.6.5" # Specify a stable version

  # Optional: You can customize the values.yaml here or use an external file
  values = [
    file("${path.module}/values.yaml") # External values.yaml file (optional)
  ]

  create_namespace = true # Create namespace if it doesn't exist

}

