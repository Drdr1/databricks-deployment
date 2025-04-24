variable "name" {
  description = "Base name for Unity Catalog resources"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = ""
}

variable "location" {
  description = "The Azure region where resources should be created"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "workspace_id" {
  description = "The ID of the Databricks workspace"
  type        = string
}

variable "workspace_url" {
  description = "The URL of the Databricks workspace"
  type        = string
}