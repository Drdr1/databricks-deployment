output "inference_cluster_id" {
  description = "The ID of the inference cluster"
  value       = databricks_cluster.inference_cluster.id
}

output "monitoring_cluster_id" {
  description = "The ID of the monitoring cluster"
  value       = databricks_cluster.monitoring_cluster.id
}

output "inference_warehouse_id" {
  description = "The ID of the inference SQL warehouse"
  value       = databricks_sql_endpoint.inference_warehouse.id
}

output "dashboard_warehouse_id" {
  description = "The ID of the dashboard SQL warehouse"
  value       = databricks_sql_endpoint.dashboard_warehouse.id
}