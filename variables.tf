###################################
# General Configuration Variables
###################################

variable "name" {
  description = "The name of the Databricks workspace"
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

variable "sku" {
  description = "The SKU of the Databricks workspace (standard, premium, or trial)"
  type        = string
  default     = "premium"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

###################################
# VNet Integration Variables
###################################

variable "no_public_ip" {
  description = "Specifies whether the workspace has no public IP"
  type        = bool
  default     = false
}

variable "vnet_id" {
  description = "The ID of the Virtual Network where the Databricks workspace should be created"
  type        = string
  default     = null
}

variable "public_subnet_name" {
  description = "The name of the Public Subnet within the Virtual Network"
  type        = string
  default     = null
}

variable "private_subnet_name" {
  description = "The name of the Private Subnet within the Virtual Network"
  type        = string
  default     = null
}

variable "public_subnet_nsg_association_id" {
  description = "The ID of the Network Security Group Association for the Public Subnet"
  type        = string
  default     = null
}

variable "private_subnet_nsg_association_id" {
  description = "The ID of the Network Security Group Association for the Private Subnet"
  type        = string
  default     = null
}

###################################
# Unity Catalog Variables
###################################

variable "enable_unity_catalog" {
  description = "Whether to enable Unity Catalog"
  type        = bool
  default     = false
}

###################################
# Compute Variables
###################################

variable "cluster_autotermination_minutes" {
  description = "How many minutes before automatically terminating due to inactivity"
  type        = number
  default     = 20
}

variable "cluster_num_workers" {
  description = "The number of workers for the cluster"
  type        = number
  default     = 2
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
  default     = "Small"
}

###################################
# Authentication Variables
###################################

variable "client_id" {
  description = "Azure AD Service Principal Client ID"
  type        = string
  default     = null
  sensitive   = true
}

variable "client_secret" {
  description = "Azure AD Service Principal Client Secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  default     = null
  sensitive   = true
}

variable "databricks_pat" {
  description = "Databricks Personal Access Token"
  type        = string
  default     = null
  sensitive   = true
}