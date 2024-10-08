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

data "bitwarden_item_login" "github_credential" {
  search = "github-homelab-pat"
}

resource "kubernetes_secret" "github_credential" {
  metadata {
    name = "github-homelab-cred"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type"="repository",

    }
  }
  data = {
    username = data.bitwarden_item_login.github_credential.username
    password = data.bitwarden_item_login.github_credential.password
    project = "default"
    type = "git"
    url = "https://github.com/benjdaun/homelab_base"

  }
}

resource "kubernetes_namespace" "secrets_management" {
  metadata {
    name = "secrets-management"
  }
}

resource "kubernetes_secret" "bitwarden_cli" {
  metadata {
    name = "bitwarden-cli"
    namespace = "secrets-management"
  }
  data = {
    BW_HOST = "https://vault.bitwarden.com/"
    BW_USERNAME = "benjamindaunoravicius@gmail.com"
    BW_PASSWORD = var.bitwarden_password

  }
}