output "app_subnet_id"     { value = azurerm_subnet.app.id }
output "public_ip_id"      { value = azurerm_public_ip.main.id }
output "public_ip_address" { value = azurerm_public_ip.main.ip_address }
