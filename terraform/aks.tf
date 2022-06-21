resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}-${random_id.random-string.dec}"
  location            = var.location
  resource_group_name = azurerm_resource_group.az_resourcegroup.name
  dns_prefix          = "${var.dns_prefix}-${random_id.random-string.dec}"
  kubernetes_version  = "1.21.9"
  

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "basic"
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name            = "agentpool"
    node_count      = var.agent_count
    vm_size         = "standard_E8a_v4"
    max_pods        = 200
  }

  #service_principal {
  #  client_id     = var.client_id
  #  client_secret = var.client_secret
  #}

  identity {
    type = "SystemAssigned"
  }


  tags = {
    Environment = "Development"
  }

}