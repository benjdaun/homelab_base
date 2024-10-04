variable "bitwarden_password" {
    type = string
    description = "Bitwarden Master Password"
    sensitive = true
}
variable "bitwarden_username" {
    type = string
    description = "Bitwarden Username"
    sensitive = true
}