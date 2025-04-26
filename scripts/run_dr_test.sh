#!/bin/bash
# Databricks Disaster Recovery Test Implementation Script
# Customized for your environment based on dev.tfvars
# With simplified authentication and updated CLI commands

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="$(pwd)"
LOG_FILE="dr_test_$(date +%Y%m%d_%H%M%S).log"

# Your environment configuration from dev.tfvars
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"  # Change to your preferred DR region
PRIMARY_RG="rg-databricks-dev"
MANAGED_RG="rg-databricks-dev-managed"
WORKSPACE_NAME="databricks-dev"

# Workspace URL
WORKSPACE_URL="https://adb-1922282054820805.5.azuredatabricks.net"

# Path to your tfvars files
DEV_TFVARS="environments/dev.tfvars"
DR_TFVARS="environments/dr.tfvars"  # Create this if you plan to use it

# Function to log messages
log() {
  local message="$1"
  local level="${2:-INFO}"
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Function to prompt for confirmation
confirm() {
  local message="$1"
  read -p "$message (y/n): " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Function to run Terraform commands with tfvars file
run_terraform() {
  local command="$1"
  local target="$2"
  local vars_file="$3"
  
  if [ -z "$vars_file" ]; then
    vars_file="$DEV_TFVARS"
  fi
  
  if [ ! -f "$vars_file" ]; then
    log "Warning: Variables file $vars_file not found. Using default variables." "WARNING"
    vars_option=""
  else
    vars_option="-var-file=$vars_file"
  fi
  
  if [ -n "$target" ]; then
    log "Running: terraform $command -target=$target $vars_option"
    terraform "$command" -target="$target" $vars_option -auto-approve
  else
    log "Running: terraform $command $vars_option"
    terraform "$command" $vars_option -auto-approve
  fi
}

# Function to use Databricks CLI to terminate a cluster
terminate_cluster() {
  local cluster_id="$1"
  
  if [ -z "$cluster_id" ]; then
    log "No cluster ID provided. Cannot terminate." "ERROR"
    return 1
  fi
  
  if command -v databricks &> /dev/null; then
    log "Using Databricks CLI to terminate cluster $cluster_id"
    
    # Get the available options for the delete command to handle version differences
    databricks clusters delete --help &> /tmp/databricks_help
    
    # Check if the command supports --permanent
    if grep -q -- "--permanent" /tmp/databricks_help; then
      log "Using --permanent flag to permanently delete the cluster"
      databricks clusters delete "$cluster_id" --permanent
    else
      # Try without the --permanent flag for newer CLI versions
      log "Permanent delete not available. Using standard delete."
      databricks clusters delete "$cluster_id" --no-wait
    fi
    
    # Check if the command was successful
    if [ $? -eq 0 ]; then
      log "Cluster termination command sent successfully" "SUCCESS"
      return 0
    else
      log "Failed to terminate cluster via CLI. Please terminate manually." "ERROR"
      log "Workspace URL: $WORKSPACE_URL" "INFO"
      read -p "Press Enter once you've terminated the cluster manually..."
      return 1
    fi
  else
    log "Databricks CLI not found. Please terminate cluster $cluster_id manually via the Databricks UI." "MANUAL"
    log "Workspace URL: $WORKSPACE_URL" "INFO"
    read -p "Press Enter once you've terminated the cluster manually..."
    return 1
  fi
}

# Function to test a component failure
test_component_failure() {
  local component_name="$1"
  local component_id="$2"
  local terraform_target="$3"
  local recovery_steps="$4"
  
  log "Starting component failure test for: $component_name" "TEST"
  log "This will simulate a failure of $component_name (ID: $component_id)"
  
  if confirm "Ready to proceed with the test?"; then
    log "Simulating failure of $component_name..." "ACTION"
    
    # Different actions depending on component type
    if [[ "$component_name" == *"Cluster"* ]]; then
      if confirm "Would you like to automatically terminate the cluster using Databricks CLI?"; then
        terminate_cluster "$component_id"
      else
        log "${YELLOW}ACTION REQUIRED: Please manually terminate $component_name (ID: $component_id) via the Databricks UI${NC}" "MANUAL"
        log "Workspace URL: $WORKSPACE_URL" "INFO"
        read -p "Press Enter once you've completed the manual failure simulation..."
      fi
    elif [[ "$component_name" == *"SQL Warehouse"* ]]; then
      log "${YELLOW}ACTION REQUIRED: Please manually stop $component_name (ID: $component_id) via the Databricks SQL UI${NC}" "MANUAL"
      log "Workspace URL: $WORKSPACE_URL" "INFO"
      read -p "Press Enter once you've completed the manual failure simulation..."
    elif [[ "$component_name" == *"Job"* ]]; then
      log "${YELLOW}ACTION REQUIRED: Please manually disable $component_name via the Databricks Jobs UI${NC}" "MANUAL"
      log "Workspace URL: $WORKSPACE_URL" "INFO"
      read -p "Press Enter once you've completed the manual failure simulation..."
    else
      log "${YELLOW}ACTION REQUIRED: Please manually disable/delete $component_name${NC}" "MANUAL"
      read -p "Press Enter once you've completed the manual failure simulation..."
    fi
    
    # Record start time for recovery
    start_time=$(date +%s)
    
    log "Component failure simulated. Beginning impact assessment..." "ASSESSMENT"
    log "${YELLOW}ACTION REQUIRED: Please document the observed impact${NC}" "MANUAL"
    read -p "Press Enter to continue to recovery phase..."
    
    log "Starting recovery process..." "RECOVERY"
    log "Recovery procedure: $recovery_steps"
    
    if confirm "Execute automated recovery with Terraform?"; then
      run_terraform "apply" "$terraform_target" "$DEV_TFVARS"
    else
      log "${YELLOW}ACTION REQUIRED: Please perform manual recovery steps${NC}" "MANUAL"
      read -p "Press Enter once you've completed the recovery steps..."
    fi
    
    # Calculate recovery time
    end_time=$(date +%s)
    recovery_duration=$((end_time - start_time))
    
    log "Recovery process completed in ${recovery_duration} seconds ($(($recovery_duration / 60)) minutes)" "SUCCESS"
    log "Running validation checks..." "VALIDATION"
    
    log "${YELLOW}ACTION REQUIRED: Validate that $component_name is functioning correctly${NC}" "MANUAL"
    if confirm "Is the component functioning correctly?"; then
      log "Test for $component_name completed successfully" "SUCCESS"
    else
      log "Component recovery validation failed. Further investigation required." "FAILURE"
    fi
  else
    log "Test for $component_name skipped" "SKIPPED"
  fi
}

# Function to create DR tfvars file
create_dr_tfvars() {
  if [ -f "$DR_TFVARS" ]; then
    log "DR tfvars file already exists: $DR_TFVARS"
    return 0
  fi
  
  log "Creating DR tfvars file for secondary region: $SECONDARY_REGION"
  
  # Create DR tfvars by modifying from dev.tfvars
  if [ -f "$DEV_TFVARS" ]; then
    # Create DR directory if it doesn't exist
    mkdir -p "$(dirname "$DR_TFVARS")"
    
    # Copy dev.tfvars to dr.tfvars with modifications
    sed "s/eastus/$SECONDARY_REGION/g; s/databricks-dev/databricks-dr/g; s/rg-databricks-dev/rg-databricks-dr/g; s/Development/DR/g" "$DEV_TFVARS" > "$DR_TFVARS"
    
    log "Created DR tfvars file: $DR_TFVARS"
  else
    log "Dev tfvars file not found: $DEV_TFVARS" "ERROR"
    return 1
  fi
}

# Function to test region failure
test_region_failure() {
  log "Starting region failure test" "TEST"
  log "This will simulate a complete failure of the $PRIMARY_REGION region"
  
  if confirm "This is a complex test that may cause extended downtime. Are you sure you want to proceed?"; then
    log "Preparing for region failover test..." "ACTION"
    
    # Create DR tfvars if needed
    if confirm "Would you like to create/update DR tfvars file for the secondary region?"; then
      create_dr_tfvars
    fi
    
    # Ensure we have state and configuration for secondary region
    if confirm "Have you already set up infrastructure in $SECONDARY_REGION?"; then
      log "Using existing secondary region setup"
    else
      log "Setting up infrastructure in $SECONDARY_REGION..."
      if confirm "Create secondary region resources now using $DR_TFVARS?"; then
        if [ -f "$DR_TFVARS" ]; then
          run_terraform "apply" "" "$DR_TFVARS"
        else
          log "DR tfvars file not found: $DR_TFVARS" "ERROR"
          if confirm "Would you like to create it now?"; then
            create_dr_tfvars
            run_terraform "apply" "" "$DR_TFVARS"
          else
            log "Cannot proceed without DR configuration" "ERROR"
            return 1
          fi
        fi
      else
        log "Cannot proceed without secondary region resources" "ERROR"
        return 1
      fi
    fi
    
    log "${YELLOW}ACTION REQUIRED: Simulate primary region failure by disconnecting services${NC}" "MANUAL"
    read -p "Press Enter once you've simulated the region failure..."
    
    # Record start time for recovery
    start_time=$(date +%s)
    
    log "Executing failover to $SECONDARY_REGION..." "FAILOVER"
    log "${YELLOW}ACTION REQUIRED: Update DNS/access points to point to secondary region${NC}" "MANUAL"
    read -p "Press Enter once you've updated access points..."
    
    log "Failover executed. Beginning validation..." "VALIDATION"
    log "${YELLOW}ACTION REQUIRED: Validate all services in secondary region${NC}" "MANUAL"
    
    if confirm "Are all services functioning correctly in the secondary region?"; then
      # Calculate recovery time
      end_time=$(date +%s)
      recovery_duration=$((end_time - start_time))
      
      log "Region failover completed successfully in ${recovery_duration} seconds ($(($recovery_duration / 60)) minutes)" "SUCCESS"
      
      if confirm "Would you like to test failback to primary region?"; then
        log "Executing failback to $PRIMARY_REGION..." "FAILBACK"
        log "${YELLOW}ACTION REQUIRED: Restore primary region services${NC}" "MANUAL"
        read -p "Press Enter once primary region is available again..."
        
        log "Redirecting traffic back to primary region..."
        log "${YELLOW}ACTION REQUIRED: Update DNS/access points back to primary region${NC}" "MANUAL"
        read -p "Press Enter once you've updated access points..."
        
        log "Validating primary region functionality..."
        if confirm "Are all services functioning correctly in the primary region?"; then
          log "Region failback completed successfully" "SUCCESS"
        else
          log "Region failback validation failed" "FAILURE"
        fi
      fi
    else
      log "Region failover validation failed" "FAILURE"
    fi
  else
    log "Region failure test skipped" "SKIPPED"
  fi
}

# Function to ensure Databricks CLI is available and authenticated
ensure_databricks_cli() {
  if ! command -v databricks &> /dev/null; then
    log "Databricks CLI not found. Manual steps will be required for some operations." "WARNING"
    log "To install Databricks CLI: pip install databricks-cli" "INFO"
    return 1
  fi
  
  # Simple authentication test
  log "Testing Databricks CLI authentication..." "INFO"
  if databricks workspace ls &> /dev/null; then
    log "Databricks CLI is authenticated and ready to use" "SUCCESS"
    return 0
  fi
  
  # If we get here, authentication is needed
  log "${YELLOW}Databricks CLI is not authenticated. Trying to authenticate now...${NC}" "WARNING"
  log "Authenticating with Databricks using browser-based auth" "INFO"
  
  # Try to authenticate
  if databricks auth login --host "$WORKSPACE_URL"; then
    log "Databricks authentication succeeded" "SUCCESS"
    return 0
  else
    log "Authentication failed. Will use manual steps for operations." "WARNING"
    return 1
  fi
}

# Main execution
main() {
  log "Databricks Disaster Recovery Test Script" "INFO"
  log "=========================================" "INFO"
  
  # Try to ensure Databricks CLI is authenticated
  ensure_databricks_cli
  
  # Ensure we're in the right directory
  if [ ! -f "terraform.tfstate" ]; then
    log "Warning: terraform.tfstate not found in current directory." "WARNING"
    log "Make sure you are running this script from your Terraform project directory." "WARNING"
    if ! confirm "Continue anyway?"; then
      log "Exiting script" "INFO"
      exit 1
    fi
  fi
  
  # Display menu
  echo -e "\n${GREEN}Select a DR test to perform:${NC}"
  echo "1) Inference Cluster Failure Test"
  echo "2) Monitoring Cluster Failure Test"
  echo "3) Dashboard SQL Warehouse Failure Test"
  echo "4) Inference SQL Warehouse Failure Test"
  echo "5) Monitoring Job Failure Test"
  echo "6) Complete Region Failure Test"
  echo "0) Exit"
  
  read -p "Enter your choice: " choice
  
  case $choice in
    1)
      test_component_failure "Inference Cluster" \
        "0426-040526-vsotra0p" \
        "module.compute.databricks_cluster.inference_cluster" \
        "Recreate cluster using Terraform and validate jobs"
      ;;
    2)
      test_component_failure "Monitoring Cluster" \
        "0426-035643-yxixlazl" \
        "module.compute.databricks_cluster.monitoring_cluster" \
        "Recreate monitoring cluster and verify monitoring jobs"
      ;;
    3)
      test_component_failure "Dashboard SQL Warehouse" \
        "ea3657fb59ca673c" \
        "module.compute.databricks_sql_endpoint.dashboard_warehouse" \
        "Recreate SQL warehouse and verify dashboard queries"
      ;;
    4)
      test_component_failure "Inference SQL Warehouse" \
        "2dfa92be4da6ac44" \
        "module.compute.databricks_sql_endpoint.inference_warehouse" \
        "Recreate inference warehouse and validate connections"
      ;;
    5)
      test_component_failure "Monitoring Job" \
        "730524707704987" \
        "module.monitoring.databricks_job.monitoring_job" \
        "Reapply job configuration and verify scheduling"
      ;;
    6)
      test_region_failure
      ;;
    0)
      log "Exiting script" "INFO"
      exit 0
      ;;
    *)
      log "Invalid choice" "ERROR"
      ;;
  esac
  
  log "DR Test completed. Results logged to $LOG_FILE" "INFO"
  
  # Offer to open log file
  if command -v less &> /dev/null; then
    if confirm "Would you like to view the test log?"; then
      less "$LOG_FILE"
    fi
  fi
}

# Execute main function
main