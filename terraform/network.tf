resource "azurerm_virtual_network" "public_vnet" {
  name = "public-vnet-${random_id.random-string.dec}"
  address_space = ["10.0.0.0/16"]
  location = var.controller_location
  resource_group_name = azurerm_resource_group.az_resourcegroup.name
}

resource "azurerm_subnet" "frontendsubnet" {
  name = "frontendSubnet-${random_id.random-string.dec}"
  resource_group_name =  azurerm_resource_group.az_resourcegroup.name
  virtual_network_name = azurerm_virtual_network.public_vnet.name
  address_prefixes = ["10.0.1.0/24"]
}