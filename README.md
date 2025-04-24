# Modular Azure Databricks Terraform Project

This Terraform project provides a modular approach to deploying Azure Databricks resources. It's designed to be flexible, maintainable, and reusable

## Project Structure

```
databricks-terraform/
├── main.tf                  # Main entry point that calls modules
├── variables.tf             # Root-level input variables
├── outputs.tf               # Root-level output values
├── providers.tf             # Provider configuration
├── terraform.tfvars.example # Example variable values
├── .gitignore               # Git ignore file
├── modules/
│   ├── workspace/           # Databricks workspace module
│   ├── unity_catalog/       # Unity Catalog module
│   ├── compute/             # Compute resources module
│   ├── inference/           # Inference tables module
│   ├── monitoring/          # Monitoring module
│   └── dashboards/          # Dashboards module
├��─ examples/                # Example configurations
│   ├── basic/               # Basic deployment example
│   └── complete/            # Complete deployment example
└── docs/                    # Documentation
```

## Modules

### Workspace Module
Creates the core Azure Databricks workspace with optional VNet injection.

### Unity Catalog Module
Sets up Unity Catalog with metastore, storage account, and access connector.

### Compute Module
Provisions Databricks clusters and SQL warehouses for different workloads.

### Inference Module
Creates databases, tables, and volumes for ML model inference.

### Monitoring Module
Sets up monitoring infrastructure including tables and data collection jobs.

### Dashboards Module
Creates SQL views and dashboard definitions for visualizing metrics.

## Usage

### Basic Usage

```hcl
module "databricks" {
  source = "path/to/databricks-terraform"

  name                        = "databricks-workspace"
  resource_group_name         = "rg-databricks"
  location                    = "eastus"
  managed_resource_group_name = "rg-databricks-managed"
  
  # Optional configurations
  enable_unity_catalog        = false
  cluster_num_workers         = 2
  
  tags = {
    Environment = "Development"
  }
}
```

### Advanced Usage

For advanced usage with VNet injection and Unity Catalog, see the complete example in the `examples/complete` directory.

## Prerequisites

- Terraform >= 1.0.0
- Azure CLI or Service Principal with appropriate permissions
- Azure subscription

## Authentication

This module supports multiple authentication methods:

### Azure CLI

```bash
az login
```

### Service Principal

```bash
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

### Databricks Authentication

For Databricks provider authentication, you can use:

1. Azure AD Service Principal
2. Databricks Personal Access Token (PAT)

## Deployment Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/databricks-terraform.git
   cd databricks-terraform
   ```

2. Create a `terraform.tfvars` file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit the `terraform.tfvars` file with your specific values.

4. Initialize Terraform:
   ```bash
   terraform init
   ```

5. Plan the deployment:
   ```bash
   terraform plan -var-file=environments/dev.tfvars -out=tfplan
   ```

6. Apply the configuration:
   ```bash
   terraform apply tfplan
   ```

## Module Configuration

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| name | The name of the Databricks workspace | string |
| resource_group_name | The name of the resource group | string |
| location | The Azure region where resources should be created | string |
| managed_resource_group_name | The name of the managed resource group for Databricks | string |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| sku | The SKU of the Databricks workspace | string | "premium" |
| enable_unity_catalog | Whether to enable Unity Catalog | bool | false |
| no_public_ip | Specifies whether the workspace has no public IP | bool | false |
| vnet_id | The ID of the Virtual Network | string | null |
| cluster_num_workers | The number of workers for clusters | number | 2 |
| sql_warehouse_size | The size of SQL warehouses | string | "Small" |

For a complete list of variables, see the `variables.tf` file.

## CI/CD Integration

This project can be integrated with Azure DevOps pipelines.

## Remote State

For production use, it's recommended to configure remote state storage. Uncomment and configure the backend block in `providers.tf`.


