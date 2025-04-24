output "monitoring_job_id" {
  description = "The ID of the monitoring job"
  value       = databricks_job.monitoring_job.id
}

output "monitoring_job_url" {
  description = "The URL of the monitoring job"
  value       = "${var.workspace_url}#job/${databricks_job.monitoring_job.id}"
}

output "monitoring_setup_job_id" {
  description = "The ID of the monitoring setup job"
  value       = databricks_job.setup_monitoring.id
}

output "monitoring_database_name" {
  description = "The name of the monitoring database"
  value       = "monitoring_db"
}