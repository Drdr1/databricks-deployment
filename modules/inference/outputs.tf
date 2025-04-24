output "inference_database_name" {
  description = "The name of the inference database or schema"
  value       = var.enable_unity_catalog ? databricks_schema.inference_schema[0].name : "inference_db"
}

output "inference_catalog_id" {
  description = "The ID of the inference catalog (if Unity Catalog is enabled)"
  value       = var.enable_unity_catalog ? databricks_catalog.inference_catalog[0].id : null
}

output "inference_schema_id" {
  description = "The ID of the inference schema (if Unity Catalog is enabled)"
  value       = var.enable_unity_catalog ? databricks_schema.inference_schema[0].id : null
}

output "inference_volume_id" {
  description = "The ID of the inference volume (if Unity Catalog is enabled)"
  value       = var.enable_unity_catalog && var.unity_catalog_metastore_id != null ? databricks_volume.inference_volume[0].id : null
}