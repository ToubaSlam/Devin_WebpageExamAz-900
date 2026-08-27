variable "project_name" {
  description = "Short name used as a prefix for all resources."
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "Deployment environment: dev or prod."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Azure VM SKU."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Linux admin user created on the VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key placed on the VM for passwordless login."
  type        = string
  sensitive   = true
}
