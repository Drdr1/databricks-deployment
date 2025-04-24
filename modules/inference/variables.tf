variable "name" {
  description = "Base name for inference resources"
  type        = string
}

variable "workspace_url" {
  description = "The URL of the Databricks workspace"
  type        = string
}

variable "enable_unity_catalog" {
  description = "Whether Unity Catalog is enabled"
  type        = bool
  default     = false
}

variable "unity_catalog_metastore_id" {
  description = "The ID of the Unity Catalog metastore"
  type        = string
  default     = null
}

variable "inference_cluster_id" {
  description = "The ID of the inference cluster"
  type        = string
}

variable "inference_warehouse_id" {
  description = "The ID of the inference SQL warehouse"
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