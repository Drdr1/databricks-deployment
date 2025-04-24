# Databricks Terraform - Main Configuration

# Create the Databricks workspace
module "workspace" {
  source = "./modules/workspace"

  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  managed_resource_group_name = var.managed_resource_group_name
  sku                         = var.sku
  tags                        = var.tags
  
  # VNet integration
  no_public_ip                       = var.no_public_ip
  vnet_id                            = var.vnet_id
  public_subnet_name                 = var.public_subnet_name
  private_subnet_name                = var.private_subnet_name
  public_subnet_nsg_association_id   = var.public_subnet_nsg_association_id
  private_subnet_nsg_association_id  = var.private_subnet_nsg_association_id
}

# Unity Catalog (optional)
# We'll use a local to determine whether to create Unity Catalog resources
locals {
  create_unity_catalog = var.enable_unity_catalog
}

module "unity_catalog" {
  source = "./modules/unity_catalog"

  # Only create if enable_unity_catalog is true
  name                = var.enable_unity_catalog ? var.name : ""
  resource_group_name = var.resource_group_name  # Use the same resource group as the workspace
  location            = var.location
  tags                = var.tags
  
  workspace_id        = module.workspace.workspace_id
  workspace_url       = module.workspace.workspace_url
}

# Compute resources (clusters and SQL warehouses)
module "compute" {
  source = "./modules/compute"

  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  managed_resource_group_name = var.managed_resource_group_name
  
  # Cluster configuration
  cluster_node_type_id            = var.cluster_node_type_id
  cluster_spark_version           = var.cluster_spark_version
  cluster_autotermination_minutes = var.cluster_autotermination_minutes
  cluster_num_workers             = var.cluster_num_workers
  
  # SQL warehouse configuration
  sql_warehouse_size          = var.sql_warehouse_size
  sql_warehouse_auto_stop_mins = var.sql_warehouse_auto_stop_mins
}

# Inference tables
module "inference" {
  source = "./modules/inference"

  name                = var.name
  workspace_url       = module.workspace.workspace_url
  enable_unity_catalog = var.enable_unity_catalog
  
  # Reference compute resources
  inference_cluster_id = module.compute.inference_cluster_id
  inference_warehouse_id = module.compute.inference_warehouse_id
  
  # Unity catalog references if enabled
  unity_catalog_metastore_id = var.enable_unity_catalog ? module.unity_catalog.metastore_id : null
  
  cluster_node_type_id  = var.cluster_node_type_id
  cluster_spark_version = var.cluster_spark_version
}

# Monitoring
module "monitoring" {
  source = "./modules/monitoring"

  name                = var.name
  workspace_url       = module.workspace.workspace_url
  
  # Reference compute resources
  monitoring_cluster_id = module.compute.monitoring_cluster_id
  
  cluster_node_type_id  = var.cluster_node_type_id
  cluster_spark_version = var.cluster_spark_version
}

# Dashboards
module "dashboards" {
  source = "./modules/dashboards"

  name                = var.name
  workspace_url       = module.workspace.workspace_url
  
  # Reference compute resources
  dashboard_warehouse_id = module.compute.dashboard_warehouse_id
  
  cluster_node_type_id  = var.cluster_node_type_id
  cluster_spark_version = var.cluster_spark_version
}