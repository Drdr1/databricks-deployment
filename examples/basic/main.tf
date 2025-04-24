module "databricks" {
  source = "../../"  # Path to the root module

  name                        = "databricks-basic"
  resource_group_name         = "rg-databricks-basic"
  location                    = "eastus"
  managed_resource_group_name = "rg-databricks-basic-managed"
  
  # Disable Unity Catalog for basic example
  enable_unity_catalog        = false
  
  # Basic cluster configuration
  cluster_num_workers         = 1
  cluster_node_type_id        = "Standard_DS3_v2"
  
  # Basic SQL warehouse configuration
  sql_warehouse_size          = "Small"
  
  tags = {
    Environment = "Development"
    Project     = "Databricks Basic"
  }
}