provider "kubernetes" {
  config_path = "~/.kube/config" # Adjust if your kubeconfig is elsewhere
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Adjust if your kubeconfig is elsewhere
  }
}
