output "vm_id"      { value = azurerm_linux_virtual_machine.main.id }
output "private_ip" { value = azurerm_network_interface.main.private_ip_address }
