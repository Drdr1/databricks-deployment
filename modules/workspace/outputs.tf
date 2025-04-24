output "workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_name" {
  description = "The name of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.name
}

output "workspace_url" {
  description = "The workspace URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "managed_resource_group_id" {
  description = "The ID of the managed resource group"
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}