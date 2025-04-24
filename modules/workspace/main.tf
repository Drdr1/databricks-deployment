# Create the resource group 
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create the Databricks workspace
resource "azurerm_databricks_workspace" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  sku                         = var.sku
  managed_resource_group_name = var.managed_resource_group_name
  
  dynamic "custom_parameters" {
    for_each = var.vnet_id != null ? [1] : []
    content {
      no_public_ip             = var.no_public_ip
      virtual_network_id       = var.vnet_id
      public_subnet_name       = var.public_subnet_name
      private_subnet_name      = var.private_subnet_name
      public_subnet_network_security_group_association_id  = var.public_subnet_nsg_association_id
      private_subnet_network_security_group_association_id = var.private_subnet_nsg_association_id
    }
  }

  tags = var.tags
  
  # Wait for the resource group to be fully created
  depends_on = [azurerm_resource_group.this]
}