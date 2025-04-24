name                        = "databricks-test"
resource_group_name         = "rg-databricks-test"
location                    = "eastus"
managed_resource_group_name = "rg-databricks-test-managed"

# Enable Unity Catalog for test
enable_unity_catalog        = true

# Test cluster configuration
cluster_num_workers         = 2
cluster_node_type_id        = "Standard_DS3_v2"
cluster_autotermination_minutes = 15

# Test SQL warehouse configuration
sql_warehouse_size          = "Small"
sql_warehouse_auto_stop_mins = 90

tags = {
  Environment = "Test"
  Project     = "Databricks Platform"
}