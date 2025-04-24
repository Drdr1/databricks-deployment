name                        = "databricks-dev"
resource_group_name         = "rg-databricks-dev"
location                    = "eastus"
managed_resource_group_name = "rg-databricks-dev-managed"
databricks_pat = "secert-here"
# Disable Unity Catalog for dev
enable_unity_catalog        = false

# Dev cluster configuration
cluster_num_workers         = 1
cluster_node_type_id        = "Standard_DS3_v2"
cluster_autotermination_minutes = 10

# Dev SQL warehouse configuration
sql_warehouse_size          = "Small"
sql_warehouse_auto_stop_mins = 60

tags = {
  Environment = "Development"
  Project     = "Databricks Platform"
}