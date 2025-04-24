output "dashboard_queries_job_id" {
  description = "The ID of the dashboard queries setup job"
  value       = databricks_job.setup_dashboard_queries.id
}

output "create_dashboards_job_id" {
  description = "The ID of the create dashboards job"
  value       = databricks_job.create_dashboards_job.id
}

output "dashboard_queries_notebook_path" {
  description = "The path of the dashboard queries notebook"
  value       = databricks_notebook.dashboard_queries_setup.path
}

output "create_dashboards_notebook_path" {
  description = "The path of the create dashboards notebook"
  value       = databricks_notebook.create_dashboards.path
}