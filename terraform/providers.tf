provider "kubernetes" {
  config_path = var.kubeconfig_file
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_file
  }
}

terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.9.0"
    }
  }
}

# Configure the Bitwarden Provider
provider "bitwarden" {
  email           = "benjamindaunoravicius@gmail.com"
  master_password = var.bitwarden_password
}
