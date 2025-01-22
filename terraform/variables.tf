variable "project_base_path" {
  type        = string
  description = "Where in the filesystem this git repo is located"
}
variable "bitwarden_password" {
  type        = string
  description = "Bitwarden Master Password"
  sensitive   = true
}
variable "bitwarden_username" {
  type        = string
  description = "Bitwarden Username"
  sensitive   = true
}

variable "kubeconfig_file" {
  type        = string
  description = "Path of the Kubeconfig"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment (dev, prod, etc.)"
}