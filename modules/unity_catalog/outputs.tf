output "metastore_id" {
  description = "The ID of the Unity Catalog metastore"
  value       = var.name != "" ? (length(databricks_metastore.this) > 0 ? databricks_metastore.this[0].id : null) : null
}

output "storage_account_name" {
  description = "The name of the storage account for Unity Catalog"
  value       = var.name != "" ? (length(azurerm_storage_account.unity_catalog) > 0 ? azurerm_storage_account.unity_catalog[0].name : null) : null
}

output "access_connector_id" {
  description = "The ID of the Databricks access connector"
  value       = var.name != "" ? (length(azurerm_databricks_access_connector.this) > 0 ? azurerm_databricks_access_connector.this[0].id : null) : null
}

output "external_location_id" {
  description = "The ID of the external location for inference data"
  value       = var.name != "" ? (length(databricks_external_location.inference_data) > 0 ? databricks_external_location.inference_data[0].id : null) : null
}