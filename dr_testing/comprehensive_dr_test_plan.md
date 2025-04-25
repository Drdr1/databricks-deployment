
# Databricks Disaster Recovery Test Plan

## Overview
This document outlines the disaster recovery testing procedures for our Databricks environment. The tests will validate our ability to recover from both component-level failures and complete region failures.

## Environment Details
- **Workspace Name**: databricks-dev
- **Workspace URL**: adb-3987377470130290.10.azuredatabricks.net
- **Resource Group**: rg-databricks-dev
- **Managed Resource Group**: rg-databricks-dev-managed

## Resources to Test

### Compute Resources
1. Inference Cluster (ID: 0425-033810-jdw4qjet)
2. Monitoring Cluster (ID: 0425-033810-dany832j)
3. Inference SQL Warehouse (ID: 7ba58c91dabcdc22)
4. Dashboard SQL Warehouse (ID: c8180a87be9de36a)

### Data Resources
1. Inference Database (Name: inference_db)

### Jobs and Notebooks
1. Monitoring Job (URL: adb-3987377470130290.10.azuredatabricks.net#job/477223882569186)
2. Dashboard Jobs
   - Create Dashboards Job
   - Setup Dashboard Queries Job
3. Inference Jobs
   - Setup Inference DB Job
4. Notebooks in /Shared directory

## Test Scenarios

### 1. Component Failure Tests

#### 1.1 Cluster Failure Recovery Test
**Objective**: Verify ability to recover from cluster failure
**Procedure**:
1. Identify the current state of the inference cluster (0425-033810-jdw4qjet)
2. Simulate failure by terminating the cluster using Databricks API
3. Attempt recovery using Terraform:
   ```bash
   # Ensure proper authentication is set up
   export DATABRICKS_HOST="adb-3987377470130290.10.azuredatabricks.net"
   export DATABRICKS_TOKEN="your-access-token"
   
   # Apply with variables file to avoid prompts
   terraform apply -var-file=terraform.tfvars -target=module.compute.databricks_cluster.inference_cluster
   ```
4. Verify cluster is operational and has the same configuration
5. Run a sample notebook to confirm functionality

#### 1.2 SQL Warehouse Failure Recovery Test
**Objective**: Verify ability to recover from SQL warehouse failure
**Procedure**:
1. Document current state of the inference warehouse (7ba58c91dabcdc22)
2. Simulate failure by stopping or deleting the warehouse
3. Recover using Terraform:
   ```bash
   # Ensure proper authentication is set up
   export DATABRICKS_HOST="adb-3987377470130290.10.azuredatabricks.net"
   export DATABRICKS_TOKEN="your-access-token"
   
   # Apply with variables file to avoid prompts
   terraform apply -var-file=terraform.tfvars -target=module.compute.databricks_sql_endpoint.inference_warehouse
   ```
4. Run test queries to verify functionality and performance

#### 1.3 Job Failure Recovery Test
**Objective**: Verify ability to recover from job configuration loss
**Procedure**:
1. Document current monitoring job configuration
2. Delete the job using Databricks API
3. Recover using Terraform:
   ```bash
   # Ensure proper authentication is set up
   export DATABRICKS_HOST="adb-3987377470130290.10.azuredatabricks.net"
   export DATABRICKS_TOKEN="your-access-token"
   
   # Apply with variables file to avoid prompts
   terraform apply -var-file=terraform.tfvars -target=module.monitoring.databricks_job.monitoring_job
   ```
4. Verify job schedule, parameters, and notebook references

#### 1.4 Notebook Recovery Test
**Objective**: Verify ability to recover lost notebooks
**Procedure**:
1. Export a copy of a critical notebook (e.g., monitoring_setup)
2. Delete the notebook from the workspace
3. Recover using Terraform:
   ```bash
   # Ensure proper authentication is set up
   export DATABRICKS_HOST="adb-3987377470130290.10.azuredatabricks.net"
   export DATABRICKS_TOKEN="your-access-token"
   
   # Apply with variables file to avoid prompts
   terraform apply -var-file=terraform.tfvars -target=module.monitoring.databricks_notebook.monitoring_setup
   ```
4. Verify notebook content and permissions

### 2. Region Failure Recovery Test

#### 2.1 Full Region Recovery Test
**Objective**: Verify ability to recover entire environment in a new region
**Procedure**:

1. **Preparation Phase**:
   - Export all necessary data from the primary region
   - Document current state of all resources
   - Create backup of Terraform state
   ```bash
   cp terraform.tfstate terraform.tfstate.backup.$(date +%s)
   ```

2. **Simulate Region Failure**:
   - For testing purposes, consider the primary region inaccessible

3. **Recovery Phase**:
   - Create a DR-specific tfvars file:
     ```bash
     cat > dr_recovery.tfvars << EOF
     # Azure region
     location = "eastus2"  # DR region
     
     # Resource naming
     resource_group_name = "rg-databricks-dev-dr"
     workspace_name = "databricks-dev-dr"
     managed_resource_group_name = "rg-databricks-dev-managed-dr"
     name = "databricks-dev-dr"
     
     # Add any other required variables
     EOF
     ```
   - Run Terraform to create infrastructure in new region:
     ```bash
     terraform apply -var-file=dr_recovery.tfvars
     ```

4. **Validation Phase**:
   - Verify all clusters, warehouses, and jobs are created with correct configurations
   - Restore data from backups
   - Run test workloads to verify functionality
   - Validate dashboards and monitoring systems

## Success Criteria

### Component Failure Recovery
1. Resources can be recovered to their original state within 30 minutes
2. No data loss occurs during recovery
3. All configurations and permissions are preserved
4. Jobs continue to run on schedule after recovery

### Region Failure Recovery
1. Complete environment can be recreated in a new region within 4 hours
2. Data integrity is maintained with minimal loss (meeting RPO objectives)
3. All services are operational after recovery
4. End-to-end workflows function as expected

## Test Documentation

For each test, document the following:

1. Test date and participants
2. Starting state (configuration, data volumes)
3. Exact steps performed
4. Recovery time achieved
5. Any issues encountered
6. Recommendations for improvement

## Test Schedule

1. Component failure tests: Monthly
2. Full region recovery test: Quarterly

## Lessons Learned from Initial Testing

1. **Authentication is Critical**: Ensure proper authentication is set up before running recovery operations. Use environment variables or a properly configured Databricks CLI profile.

2. **Variable Management**: Always use a tfvars file to provide all required variables to avoid interactive prompts during recovery.

3. **Workspace Configuration**: Be careful when modifying workspace-level resources as this can cause the entire workspace to be recreated, which is time-consuming and potentially disruptive.

4. **Managed Resource Group Names**: Ensure the managed resource group name in your recovery configuration matches what's expected in your Terraform code to avoid unnecessary workspace recreation.

5. **Testing Scope**: Start with testing individual component recovery before attempting full region recovery to identify and resolve issues in a controlled manner.

6. **Automation**: Use automation scripts to streamline the recovery process and reduce human error during DR scenarios.

## Appendix: Recovery Commands Reference

```bash
# Set up authentication
export DATABRICKS_HOST="adb-3987377470130290.10.azuredatabricks.net"
export DATABRICKS_TOKEN="your-access-token"

# Recover specific resources
terraform apply -var-file=terraform.tfvars -target=module.compute.databricks_cluster.inference_cluster
terraform apply -var-file=terraform.tfvars -target=module.compute.databricks_cluster.monitoring_cluster
terraform apply -var-file=terraform.tfvars -target=module.compute.databricks_sql_endpoint.dashboard_warehouse
terraform apply -var-file=terraform.tfvars -target=module.compute.databricks_sql_endpoint.inference_warehouse

# Recover all resources in a module
terraform apply -var-file=terraform.tfvars -target=module.compute
terraform apply -var-file=terraform.tfvars -target=module.dashboards
terraform apply -var-file=terraform.tfvars -target=module.inference
terraform apply -var-file=terraform.tfvars -target=module.monitoring

# Full environment recovery
terraform apply -var-file=terraform.tfvars

# DR region recovery
terraform apply -var-file=dr_recovery.tfvars
```

## Appendix: Automated DR Testing Script

For automated DR testing, use the script at `/home/ahmeddarder/databricks-terraform/dr_testing/run_dr_test.sh`. This script automates the process of:

1. Simulating component failures
2. Executing recovery procedures
3. Verifying successful recovery
4. Documenting recovery times and results

Before running the script, update the configuration variables at the top of the file with your specific environment details and authentication information.
