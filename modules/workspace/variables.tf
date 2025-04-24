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