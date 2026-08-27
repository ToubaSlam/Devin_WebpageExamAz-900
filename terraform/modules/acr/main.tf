# ACR stores the Docker images that get deployed to the VM.
# Basic SKU is free-tier eligible for a portfolio project.
resource "azurerm_container_registry" "main" {
  # ACR names must be globally unique and alphanumeric only.
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}
