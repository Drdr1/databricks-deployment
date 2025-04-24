terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
  
  # Uncomment this block to use Azure Storage for remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstateaccount"
  #   container_name       = "tfstate"
  #   key                  = "databricks.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = "955faad9-ebe9-4a85-9974-acae429ae877"

}

# Configure the Databricks provider at the root level
# This will be used for all modules after the workspace is created
provider "databricks" {
  host = module.workspace.workspace_url
  token = var.databricks_pat  # Use a variable for the PAT token

  # Use Azure CLI authentication by default
  # This will use the same credentials as the Azure provider
  
  # Alternatively, you can use a PAT token:
  # token = var.databricks_pat
}

# Create a local file to store the workspace URL for debugging
resource "local_file" "workspace_url" {
  content  = module.workspace.workspace_url
  filename = "${path.module}/workspace_url.txt"
  depends_on = [module.workspace]
}


