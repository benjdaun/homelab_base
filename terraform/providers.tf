provider "kubernetes" {
  config_path = "~/.kube/config" # Adjust if your kubeconfig is elsewhere
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Adjust if your kubeconfig is elsewhere
  }
}

provider "kubectl" {
  
}
terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.9.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

# Configure the Bitwarden Provider
provider "bitwarden" {
  email = "benjamindaunoravicius@gmail.com"
  master_password = var.bitwarden_password
}
