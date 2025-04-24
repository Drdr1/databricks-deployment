module "databricks" {
  source = "../../"  # Path to the root module

  name                        = "databricks-complete"
  resource_group_name         = "rg-databricks-complete"
  location                    = "eastus"
  managed_resource_group_name = "rg-databricks-complete-managed"
  
  # VNet integration
  no_public_ip                = true
  vnet_id                     = azurerm_virtual_network.databricks_vnet.id
  public_subnet_name          = azurerm_subnet.public.name
  private_subnet_name         = azurerm_subnet.private.name
  public_subnet_nsg_association_id  = azurerm_network_security_group_association.public.id
  private_subnet_nsg_association_id = azurerm_network_security_group_association.private.id
  
  # Enable Unity Catalog
  enable_unity_catalog        = true
  
  # Advanced cluster configuration
  cluster_num_workers         = 2
  cluster_node_type_id        = "Standard_DS4_v2"
  cluster_spark_version       = "11.3.x-scala2.12"
  cluster_autotermination_minutes = 30
  
  # SQL warehouse configuration
  sql_warehouse_size          = "Medium"
  sql_warehouse_auto_stop_mins = 60
  
  tags = {
    Environment = "Production"
    Department  = "Data Science"
    Project     = "ML Platform"
  }
}

# Create a VNet for Databricks
resource "azurerm_resource_group" "network" {
  name     = "rg-databricks-network"
  location = "eastus"
}

resource "azurerm_virtual_network" "databricks_vnet" {
  name                = "vnet-databricks"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "public" {
  name                 = "snet-databricks-public"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.databricks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "databricks-delegation"
    
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private" {
  name                 = "snet-databricks-private"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.databricks_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "databricks-delegation"
    
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "databricks_nsg" {
  name                = "nsg-databricks"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.databricks_nsg.id
}

resource "azurerm_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.databricks_nsg.id
}