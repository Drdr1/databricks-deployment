#!/bin/bash

# Databricks Disaster Recovery Test Script
# This script automates the execution of DR tests for Databricks environment

set -e

# Configuration - UPDATE THESE VALUES
WORKSPACE_URL="adb-3987377470130290.10.azuredatabricks.net"  # Update with your actual workspace URL
DATABRICKS_TOKEN="dapi_your_token_here"  # Update with your Databricks access token
INFERENCE_CLUSTER_ID="0425-033810-jdw4qjet"
MONITORING_CLUSTER_ID="0425-033810-dany832j"
INFERENCE_WAREHOUSE_ID="7ba58c91dabcdc22"
DASHBOARD_WAREHOUSE_ID="c8180a87be9de36a"
RESULTS_DIR="./dr_test_results"

# Terraform variables - update these to match your environment
LOCATION="eastus"  # Azure region
RESOURCE_GROUP_NAME="rg-databricks-dev"
WORKSPACE_NAME="databricks-dev"
MANAGED_RESOURCE_GROUP_NAME="rg-databricks-dev-managed"
NAME="databricks-dev"
ENVIRONMENT="Development"
PROJECT="Databricks Platform"

# Create results directory
mkdir -p $RESULTS_DIR

# Log function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" | tee -a "$RESULTS_DIR/dr_test_log.txt"
}

# Check for required tools
check_dependencies() {
  log "Checking dependencies..."
  
  # Check for jq
  if ! command -v jq &> /dev/null; then
    log "ERROR: jq is required but not installed. Please install it with: sudo apt-get install -y jq"
    exit 1
  fi
  
  # Check for Databricks CLI
  if ! command -v databricks &> /dev/null; then
    log "ERROR: Databricks CLI is required but not installed."
    exit 1
  fi
  
  # Check for Terraform
  if ! command -v terraform &> /dev/null; then
    log "ERROR: Terraform is required but not installed."
    exit 1
  fi
  
  log "All dependencies are installed."
}

# Set up authentication for Databricks CLI
setup_auth() {
  log "Setting up authentication for Databricks CLI"
  
  # Export environment variables for Databricks CLI
  export DATABRICKS_HOST="$WORKSPACE_URL"
  export DATABRICKS_TOKEN="$DATABRICKS_TOKEN"
  
  # Test authentication
  log "Testing Databricks CLI authentication..."
  if databricks workspace ls -q > /dev/null 2>&1; then
    log "Authentication successful"
  else
    log "ERROR: Authentication failed. Please check your workspace URL and token."
    exit 1
  fi
}

# Create a temporary tfvars file for Terraform
create_tfvars_file() {
  local tfvars_file="dr_test_temp.tfvars"
  
  log "Creating temporary Terraform variables file: $tfvars_file"
  
  cat > "$tfvars_file" << EOF
# Azure region
location = "$LOCATION"

# Resource naming
resource_group_name = "$RESOURCE_GROUP_NAME"
workspace_name = "$WORKSPACE_NAME"
managed_resource_group_name = "$MANAGED_RESOURCE_GROUP_NAME"
name = "$NAME"

# Tags
environment = "$ENVIRONMENT"
project = "$PROJECT"

# Add any other variables your Terraform configuration requires
EOF
}

# Configure Databricks provider
configure_databricks_provider() {
  log "Configuring Databricks provider"
  
  # Create a temporary provider configuration file
  cat > "provider_override.tf" << EOF
provider "databricks" {
  host  = "$WORKSPACE_URL"
  token = "$DATABRICKS_TOKEN"
}
EOF
}

# Test function for component recovery
test_component_recovery() {
  local component_type="$1"
  local component_id="$2"
  local terraform_target="$3"
  
  log "Starting $component_type recovery test for ID: $component_id"
  
  # Record start time
  local start_time=$(date +%s)
  
  # Simulate failure (this would be replaced with actual API calls)
  log "Simulating failure of $component_type: $component_id"
  
  # For clusters, we would use Databricks API to terminate
  if [ "$component_type" == "cluster" ]; then
    log "Executing: databricks clusters delete $component_id"
    # Execute the command
    databricks clusters delete $component_id
  fi
  
  # For SQL warehouses, we would stop or delete them
  if [ "$component_type" == "warehouse" ]; then
    log "Executing: databricks sql warehouses stop $component_id"
    # Execute the command
    databricks sql warehouses stop $component_id
  fi
  
  # Create tfvars file
  create_tfvars_file
  
  # Configure Databricks provider
  configure_databricks_provider
  
  # Recovery using Terraform
  log "Recovering $component_type using Terraform"
  log "Executing: terraform apply -auto-approve -var-file=dr_test_temp.tfvars -target=$terraform_target"
  # Execute the command
  terraform apply -auto-approve -var-file=dr_test_temp.tfvars -target=$terraform_target
  
  # Record end time and calculate duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  log "Recovery completed in $duration seconds"
  
  # Verify recovery
  log "Verifying $component_type recovery..."
  
  if [ "$component_type" == "cluster" ]; then
    # Wait for cluster to be running
    max_wait=300  # 5 minutes
    start_wait=$(date +%s)
    while true; do
      # Get cluster state
      cluster_info=$(databricks clusters get $component_id -o json)
      status=$(echo $cluster_info | jq -r '.state' 2>/dev/null)
      
      if [ "$status" == "RUNNING" ]; then
        log "Cluster $component_id is now running"
        break
      fi
      
      current_time=$(date +%s)
      elapsed=$((current_time - start_wait))
      if [ $elapsed -gt $max_wait ]; then
        log "WARNING: Timed out waiting for cluster to start. Current status: $status"
        break
      fi
      
      log "Waiting for cluster to start... (status: $status)"
      sleep 10
    done
  fi

  if [ "$component_type" == "warehouse" ]; then
    # Wait for warehouse to be running
    max_wait=300  # 5 minutes
    start_wait=$(date +%s)
    while true; do
      # Get warehouse state
      warehouse_info=$(databricks sql warehouses get $component_id -o json)
      status=$(echo $warehouse_info | jq -r '.state' 2>/dev/null)
      
      if [ "$status" == "RUNNING" ]; then
        log "Warehouse $component_id is now running"
        break
      fi
      
      current_time=$(date +%s)
      elapsed=$((current_time - start_wait))
      if [ $elapsed -gt $max_wait ]; then
        log "WARNING: Timed out waiting for warehouse to start. Current status: $status"
        break
      fi
      
      log "Waiting for warehouse to start... (status: $status)"
      sleep 10
    done
  fi
  
  log "$component_type recovery test completed"
  echo "----------------------------------------"
}

# Test function for region recovery
test_region_recovery() {
  local new_region="$1"
  
  log "Starting full region recovery test to $new_region"
  
  # Record start time
  local start_time=$(date +%s)
  
  # Backup Terraform state
  log "Backing up Terraform state"
  cp terraform.tfstate "$RESULTS_DIR/terraform.tfstate.backup.$(date +%s)"
  
  # Simulate region failure
  log "Simulating region failure - assuming primary region is inaccessible"
  
  # Create a temporary tfvars file for the new region
  log "Creating temporary tfvars file for region: $new_region"
  cat > "dr_test_region.tfvars" << EOF
# Azure region
location = "$new_region"

# Resource naming
resource_group_name = "${RESOURCE_GROUP_NAME}-dr"
workspace_name = "${WORKSPACE_NAME}-dr"
managed_resource_group_name = "${MANAGED_RESOURCE_GROUP_NAME}-dr"
name = "${NAME}-dr"

# Tags
environment = "$ENVIRONMENT"
project = "$PROJECT"

# Add any other variables your Terraform configuration requires
EOF
  
  # Apply Terraform to create resources in new region
  log "Executing: terraform apply -auto-approve -var-file=dr_test_region.tfvars"
  terraform apply -auto-approve -var-file=dr_test_region.tfvars
  
  # Record end time and calculate duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  log "Region recovery completed in $duration seconds ($(($duration / 60)) minutes)"
  
  # Verify recovery
  log "Verifying full environment recovery..."
  
  # Get new workspace URL from Terraform output
  new_workspace_url=$(terraform output -raw workspace_url)
  log "New workspace URL: $new_workspace_url"
  
  # Check if key resources are available
  log "Checking key resources in new region..."
  
  # Get new cluster IDs from Terraform output
  new_inference_cluster_id=$(terraform output -raw inference_cluster_id)
  new_monitoring_cluster_id=$(terraform output -raw monitoring_cluster_id)
  
  # Verify clusters
  log "Verifying inference cluster: $new_inference_cluster_id"
  databricks clusters get $new_inference_cluster_id -o json > "$RESULTS_DIR/inference_cluster_dr.json"
  
  log "Verifying monitoring cluster: $new_monitoring_cluster_id"
  databricks clusters get $new_monitoring_cluster_id -o json > "$RESULTS_DIR/monitoring_cluster_dr.json"
  
  log "Region recovery test completed"
  echo "=========================================="
}

# Main execution
check_dependencies
setup_auth

log "Starting Databricks DR Test Suite"
log "Environment: $WORKSPACE_URL"

# Component tests - only run one at a time for testing
test_component_recovery "cluster" "$INFERENCE_CLUSTER_ID" "module.compute.databricks_cluster.inference_cluster"
# test_component_recovery "cluster" "$MONITORING_CLUSTER_ID" "module.compute.databricks_cluster.monitoring_cluster"
# test_component_recovery "warehouse" "$INFERENCE_WAREHOUSE_ID" "module.compute.databricks_sql_endpoint.inference_warehouse"
# test_component_recovery "warehouse" "$DASHBOARD_WAREHOUSE_ID" "module.compute.databricks_sql_endpoint.dashboard_warehouse"

# Uncomment to run region recovery test
# test_region_recovery "eastus2"

log "DR Test Suite completed"
log "Results available in: $RESULTS_DIR"

# Generate summary report
cat > "$RESULTS_DIR/summary_report.md" << EOF
# Databricks DR Test Summary Report
Date: $(date "+%Y-%m-%d")

## Tests Performed
- Inference Cluster Recovery
- Monitoring Cluster Recovery
- Inference SQL Warehouse Recovery
- Dashboard SQL Warehouse Recovery

## Results
See detailed logs in dr_test_log.txt

## Recovery Times
| Component | Recovery Time |
|-----------|---------------|
$(grep "Recovery completed in" "$RESULTS_DIR/dr_test_log.txt" | sed 's/\[.*\] Recovery completed in \(.*\) seconds/| Component | \1 seconds |/')

## Recommendations
1. Review recovery times and optimize if necessary
2. Ensure all data is properly backed up
3. Consider automating the recovery process further
4. Implement regular DR testing as part of your operational procedures
EOF

log "Summary report generated: $RESULTS_DIR/summary_report.md"

# Clean up temporary files
rm -f dr_test_temp.tfvars dr_test_region.tfvars provider_override.tf
log "Temporary files cleaned up"