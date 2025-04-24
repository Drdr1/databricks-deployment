variable "name" {
  description = "Base name for dashboard resources"
  type        = string
}

variable "workspace_url" {
  description = "The URL of the Databricks workspace"
  type        = string
}

variable "dashboard_warehouse_id" {
  description = "The ID of the dashboard SQL warehouse"
  type        = string
}

variable "cluster_node_type_id" {
  description = "The node type ID for the Databricks cluster"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "cluster_spark_version" {
  description = "The Spark version for the cluster"
  type        = string
  default     = "11.3.x-scala2.12"
}