# Databricks workspace access connector for Unity Catalog
resource "azurerm_databricks_access_connector" "this" {
  count               = var.name != "" ? 1 : 0
  name                = "${var.name}-connector"
  resource_group_name = var.resource_group_name
  location            = var.location
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

# Storage account for Unity Catalog metastore
resource "azurerm_storage_account" "unity_catalog" {
  count                    = var.name != "" ? 1 : 0
  name                     = replace("${var.name}metastore", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  tags                     = var.tags
}

resource "azurerm_storage_container" "unity_catalog" {
  count                 = var.name != "" ? 1 : 0
  name                  = "metastore"
  storage_account_name  = azurerm_storage_account.unity_catalog[0].name
  container_access_type = "private"
}

# Grant the access connector the Storage Blob Data Contributor role on the storage account
resource "azurerm_role_assignment" "storage_contributor" {
  count                = var.name != "" ? 1 : 0
  scope                = azurerm_storage_account.unity_catalog[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this[0].identity[0].principal_id
}

# Create Unity Catalog metastore
resource "databricks_metastore" "this" {
  count = var.name != "" ? 1 : 0
  name  = "${var.name}-metastore"
  storage_root = "abfss://metastore@${azurerm_storage_account.unity_catalog[0].name}.dfs.core.windows.net/"
  owner        = "account users"
}

resource "databricks_metastore_assignment" "this" {
  count              = var.name != "" ? 1 : 0
  metastore_id       = databricks_metastore.this[0].id
  workspace_id       = var.workspace_id
}

# Set the default catalog using the recommended resource
# The correct resource is databricks_catalog, not databricks_default_namespace_setting
resource "databricks_catalog" "default_catalog" {
  count      = var.name != "" ? 1 : 0
  name       = "hive_metastore"
  comment    = "Default catalog"
  properties = {
    purpose = "default"
  }
  depends_on = [databricks_metastore_assignment.this]
}

# Create a Unity Catalog external location using the storage account
resource "databricks_storage_credential" "external_storage" {
  count = var.name != "" ? 1 : 0
  name = "external-storage-credential"
  
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.this[0].id
  }
  
  comment = "Managed identity credential for external storage"
}

resource "databricks_external_location" "inference_data" {
  count = var.name != "" ? 1 : 0
  name = "inference-data"
  url = "abfss://inference@${azurerm_storage_account.unity_catalog[0].name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.external_storage[0].name
  comment = "External location for inference data"
}