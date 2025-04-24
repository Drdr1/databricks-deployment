###################################
# Workspace Outputs
###################################

output "workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = module.workspace.workspace_id
}

output "workspace_name" {
  description = "The name of the Databricks workspace"
  value       = module.workspace.workspace_name
}

output "workspace_url" {
  description = "The workspace URL of the Databricks workspace"
  value       = module.workspace.workspace_url
}

###################################
# Unity Catalog Outputs
###################################

output "unity_catalog_enabled" {
  description = "Whether Unity Catalog is enabled"
  value       = var.enable_unity_catalog
}

output "unity_catalog_metastore_id" {
  description = "The ID of the Unity Catalog metastore"
  value       = var.enable_unity_catalog ? module.unity_catalog[0].metastore_id : null
}

output "unity_catalog_storage_account" {
  description = "The name of the storage account for Unity Catalog"
  value       = var.enable_unity_catalog ? module.unity_catalog[0].storage_account_name : null
}

###################################
# Compute Outputs
###################################

output "inference_cluster_id" {
  description = "The ID of the inference cluster"
  value       = module.compute.inference_cluster_id
}

output "monitoring_cluster_id" {
  description = "The ID of the monitoring cluster"
  value       = module.compute.monitoring_cluster_id
}

output "inference_warehouse_id" {
  description = "The ID of the inference SQL warehouse"
  value       = module.compute.inference_warehouse_id
}

output "dashboard_warehouse_id" {
  description = "The ID of the dashboard SQL warehouse"
  value       = module.compute.dashboard_warehouse_id
}

###################################
# Monitoring Outputs
###################################

output "monitoring_job_url" {
  description = "The URL of the monitoring job"
  value       = module.monitoring.monitoring_job_url
}

###################################
# Inference Outputs
###################################

output "inference_database_name" {
  description = "The name of the inference database or schema"
  value       = module.inference.inference_database_name
}