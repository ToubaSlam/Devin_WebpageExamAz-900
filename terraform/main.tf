terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.105"
    }
  }

  # Remote state stored in Azure Blob Storage so CI and every team member
  # share the same state file and cannot apply conflicting changes.
  backend "azurerm" {
    resource_group_name  = "portfolio-tfstate-rg"
    storage_account_name = "portfoliotfstate"
    container_name       = "tfstate"
    key                  = "portfolio.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source              = "./modules/networking"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = local.common_tags
}

module "acr" {
  source              = "./modules/acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = local.common_tags
}

module "vm" {
  source              = "./modules/vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  subnet_id           = module.networking.app_subnet_id
  public_ip_id        = module.networking.public_ip_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  acr_login_server    = module.acr.login_server
  tags                = local.common_tags
}

locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
