variable "name" {
  description = "The name prefix for compute resources"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources should be created"
  type        = string
}

variable "managed_resource_group_name" {
  description = "The name of the managed resource group for Databricks"
  type        = string
}

variable "cluster_autotermination_minutes" {
  description = "How many minutes before automatically terminating due to inactivity"
  type        = number
  default     = 20
}

variable "cluster_num_workers" {
  description = "The number of workers for the cluster"
  type        = number
  default     = 0  # Default to single-node clusters
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

variable "sql_warehouse_auto_stop_mins" {
  description = "Number of minutes of inactivity after which the SQL warehouse will automatically stop"
  type        = number
  default     = 120
}

variable "sql_warehouse_size" {
  description = "The size of the SQL warehouse (e.g., 2X-Small, Small, Medium, Large, etc.)"
  type        = string
  default     = "2X-Small"
}