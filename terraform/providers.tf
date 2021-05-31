provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "az_resourcegroup" {
  name     = "${var.resource_group_name}-${random_id.random-string.dec}"
  location = var.location

  tags = {
    environment = "Nginx AKS demo"
  }
}