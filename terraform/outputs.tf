output "resource_group_name" {
  description = "Name of the Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the Linux VM."
  value       = module.networking.public_ip_address
}

output "acr_login_server" {
  description = "ACR login server (e.g. myregistry.azurecr.io)."
  value       = module.acr.login_server
}

output "ssh_command" {
  description = "Ready-to-use SSH command."
  value       = "ssh ${var.admin_username}@${module.networking.public_ip_address}"
}
