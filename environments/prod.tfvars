name                        = "databricks-prod"
resource_group_name         = "rg-databricks-prod"
location                    = "eastus"
managed_resource_group_name = "rg-databricks-prod-managed"

# Enable Unity Catalog for prod
enable_unity_catalog        = true

# VNet integration for prod
no_public_ip                = true
vnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-databricks-prod"
public_subnet_name          = "snet-databricks-public"
private_subnet_name         = "snet-databricks-private"

# Prod cluster configuration
cluster_num_workers         = 4
cluster_node_type_id        = "Standard_DS4_v2"
cluster_autotermination_minutes = 30

# Prod SQL warehouse configuration
sql_warehouse_size          = "Medium"
sql_warehouse_auto_stop_mins = 120

tags = {
  Environment = "Production"
  Department  = "Data Science"
  Project     = "Databricks Platform"
}