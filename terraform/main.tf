resource "helm_release" "argo_cd" {
  name       = "argocd"
  namespace  = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.6.5" # Specify a stable version

  # Optional: You can customize the values.yaml here or use an external file
  values = [
    file("${path.module}/argocd-values.yaml"),
    file("${path.module}/argocd-values-${terraform.workspace}.yaml")
  ]


  create_namespace = true # Create namespace if it doesn't exist

}

data "bitwarden_item_login" "github_credential" {
  search = "github-homelab-pat"
}

resource "kubernetes_secret" "github_credential" {
  metadata {
    name      = "github-homelab-cred"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository",

    }
  }
  data = {
    username = data.bitwarden_item_login.github_credential.username
    password = data.bitwarden_item_login.github_credential.password
    project  = "default"
    type     = "git"
    url      = "https://github.com/benjdaun/homelab_base"

  }
}

resource "kubernetes_namespace" "secrets_management" {
  metadata {
    name = "secrets-management"
  }
}

resource "kubernetes_secret" "bitwarden_cli" {
  metadata {
    name      = "bitwarden-cli"
    namespace = "secrets-management"
  }
  data = {
    BW_HOST     = "https://vault.bitwarden.com/"
    BW_USERNAME = var.bitwarden_username
    BW_PASSWORD = var.bitwarden_password

  }
}

resource "kubernetes_manifest" "homelab_base_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "homelab-base-apps"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/benjdaun/homelab_base"
        targetRevision = "main"
        path           = "base-applications"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
  depends_on = [helm_release.argo_cd, kubernetes_secret.github_credential]
}



