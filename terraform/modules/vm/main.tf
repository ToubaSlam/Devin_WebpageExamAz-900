resource "azurerm_network_interface" "main" {
  name                = "${var.project_name}-${var.environment}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.project_name}-${var.environment}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # cloud-init runs once on first boot: installs Docker Engine + Compose plugin.
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    acr_login_server = var.acr_login_server
    admin_username   = var.admin_username
  }))
}
