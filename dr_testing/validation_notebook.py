# Databricks notebook source
# MAGIC %md
# MAGIC # Databricks Disaster Recovery Validation Notebook
# MAGIC 
# MAGIC This notebook validates the functionality of a recovered Databricks environment after DR testing.
# MAGIC It checks:
# MAGIC 1. Cluster connectivity
# MAGIC 2. SQL warehouse functionality
# MAGIC 3. Database access
# MAGIC 4. Job execution
# MAGIC 5. Data integrity

# COMMAND ----------

# MAGIC %md
# MAGIC ## Environment Configuration

# COMMAND ----------

# Define environment parameters
import os
import json
from datetime import datetime

# These would typically be passed as notebook parameters
inference_cluster_id = dbutils.widgets.get("inference_cluster_id") or "0425-033810-jdw4qjet"
monitoring_cluster_id = dbutils.widgets.get("monitoring_cluster_id") or "0425-033810-dany832j"
inference_warehouse_id = dbutils.widgets.get("inference_warehouse_id") or "7ba58c91dabcdc22"
dashboard_warehouse_id = dbutils.widgets.get("dashboard_warehouse_id") or "c8180a87be9de36a"
inference_db_name = dbutils.widgets.get("inference_db_name") or "inference_db"

# Create validation results dictionary
validation_results = {
  "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
  "environment": spark.conf.get("spark.databricks.clusterUsageTags.clusterName"),
  "tests": {}
}

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Cluster Connectivity Validation

# COMMAND ----------

def validate_cluster(cluster_id, cluster_name):
  """Validate that a cluster is accessible and running"""
  import time
  from databricks.sdk import WorkspaceClient
  
  print(f"Validating cluster: {cluster_name} ({cluster_id})")
  
  try:
    # Initialize Databricks workspace client
    w = WorkspaceClient()
    
    # Get cluster info
    cluster = w.clusters.get(cluster_id)
    
    # Check if cluster is running or can be started
    if cluster.state.value == "RUNNING":
      status = "PASSED"
      message = f"Cluster {cluster_name} is running"
    elif cluster.state.value in ["TERMINATED", "TERMINATING"]:
      # Start the cluster
      print(f"Starting cluster {cluster_name}...")
      w.clusters.start(cluster_id)
      
      # Wait for cluster to start (with timeout)
      max_wait_seconds = 300
      start_time = time.time()
      while time.time() - start_time < max_wait_seconds:
        cluster = w.clusters.get(cluster_id)
        if cluster.state.value == "RUNNING":
          status = "PASSED"
          message = f"Cluster {cluster_name} started successfully"
          break
        elif cluster.state.value in ["PENDING", "RESIZING"]:
          time.sleep(10)
          continue
        else:
          status = "FAILED"
          message = f"Cluster {cluster_name} in unexpected state: {cluster.state.value}"
          break
      else:
        status = "FAILED"
        message = f"Timed out waiting for cluster {cluster_name} to start"
    else:
      status = "FAILED"
      message = f"Cluster {cluster_name} in unexpected state: {cluster.state.value}"
      
  except Exception as e:
    status = "FAILED"
    message = f"Error validating cluster {cluster_name}: {str(e)}"
  
  print(f"Result: {status} - {message}")
  return {"status": status, "message": message}

# Validate inference cluster
validation_results["tests"]["inference_cluster"] = validate_cluster(
  inference_cluster_id, "Inference Cluster"
)

# Validate monitoring cluster
validation_results["tests"]["monitoring_cluster"] = validate_cluster(
  monitoring_cluster_id, "Monitoring Cluster"
)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. SQL Warehouse Validation

# COMMAND ----------

def validate_sql_warehouse(warehouse_id, warehouse_name):
  """Validate that a SQL warehouse is accessible and can execute queries"""
  from databricks.sdk import WorkspaceClient
  from databricks.sdk.service import sql
  
  print(f"Validating SQL warehouse: {warehouse_name} ({warehouse_id})")
  
  try:
    # Initialize Databricks workspace client
    w = WorkspaceClient()
    
    # Get warehouse info
    warehouse = w.warehouses.get(warehouse_id)
    
    # Check if warehouse is running or can be started
    if warehouse.state == sql.EndpointState.RUNNING:
      status = "PASSED"
      message = f"Warehouse {warehouse_name} is running"
    else:
      # Start the warehouse
      print(f"Starting warehouse {warehouse_name}...")
      w.warehouses.start(warehouse_id)
      
      # Check if warehouse started
      warehouse = w.warehouses.get(warehouse_id)
      if warehouse.state == sql.EndpointState.RUNNING:
        status = "PASSED"
        message = f"Warehouse {warehouse_name} started successfully"
      else:
        status = "FAILED"
        message = f"Warehouse {warehouse_name} failed to start, state: {warehouse.state}"
    
    # If warehouse is running, test a simple query
    if status == "PASSED":
      try:
        # Execute a simple test query
        statement = w.statement_execution.execute_statement(
          warehouse_id=warehouse_id,
          statement="SELECT 1 as test_value",
          wait_timeout=60
        )
        
        if statement.status.state == sql.StatementState.SUCCEEDED:
          message += " and executed test query successfully"
        else:
          status = "WARNING"
          message += f" but test query execution failed: {statement.status.state}"
      except Exception as e:
        status = "WARNING"
        message += f" but test query execution failed: {str(e)}"
      
  except Exception as e:
    status = "FAILED"
    message = f"Error validating warehouse {warehouse_name}: {str(e)}"
  
  print(f"Result: {status} - {message}")
  return {"status": status, "message": message}

# Validate inference warehouse
validation_results["tests"]["inference_warehouse"] = validate_sql_warehouse(
  inference_warehouse_id, "Inference Warehouse"
)

# Validate dashboard warehouse
validation_results["tests"]["dashboard_warehouse"] = validate_sql_warehouse(
  dashboard_warehouse_id, "Dashboard Warehouse"
)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Database Access Validation

# COMMAND ----------

def validate_database(db_name):
  """Validate that a database exists and is accessible"""
  print(f"Validating database: {db_name}")
  
  try:
    # Check if database exists
    databases = spark.sql("SHOW DATABASES").collect()
    db_exists = any(row.databaseName.lower() == db_name.lower() for row in databases)
    
    if db_exists:
      # Try to use the database
      spark.sql(f"USE {db_name}")
      
      # Get tables in the database
      tables = spark.sql("SHOW TABLES").collect()
      table_count = len(tables)
      
      status = "PASSED"
      message = f"Database {db_name} exists and contains {table_count} tables"
    else:
      status = "FAILED"
      message = f"Database {db_name} does not exist"
      
  except Exception as e:
    status = "FAILED"
    message = f"Error validating database {db_name}: {str(e)}"
  
  print(f"Result: {status} - {message}")
  return {"status": status, "message": message}

# Validate inference database
validation_results["tests"]["inference_database"] = validate_database(inference_db_name)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Job Execution Validation

# COMMAND ----------

def validate_job(job_name):
  """Validate that a job exists and can be triggered"""
  from databricks.sdk import WorkspaceClient
  
  print(f"Validating job: {job_name}")
  
  try:
    # Initialize Databricks workspace client
    w = WorkspaceClient()
    
    # Find job by name
    jobs = w.jobs.list()
    matching_jobs = [job for job in jobs if job.settings.name == job_name]
    
    if matching_jobs:
      job = matching_jobs[0]
      job_id = job.job_id
      
      # Don't actually run the job in validation, just check it exists
      status = "PASSED"
      message = f"Job {job_name} (ID: {job_id}) exists and is configured"
    else:
      status = "FAILED"
      message = f"Job {job_name} not found"
      
  except Exception as e:
    status = "FAILED"
    message = f"Error validating job {job_name}: {str(e)}"
  
  print(f"Result: {status} - {message}")
  return {"status": status, "message": message}

# Validate monitoring job
validation_results["tests"]["monitoring_job"] = validate_job("Monitoring Job")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Data Integrity Validation
# MAGIC This would be customized based on your specific data and requirements

# COMMAND ----------

def validate_data_integrity():
  """Validate data integrity by checking key tables and metrics"""
  print("Validating data integrity")
  
  try:
    # This is a placeholder - you would replace with actual data validation
    # For example, checking row counts, recent data timestamps, etc.
    
    # Example: Check if a key table exists and has expected data
    if spark.catalog.tableExists(f"{inference_db_name}.your_key_table"):
      row_count = spark.sql(f"SELECT COUNT(*) as count FROM {inference_db_name}.your_key_table").collect()[0].count
      
      if row_count > 0:
        status = "PASSED"
        message = f"Data integrity check passed: your_key_table has {row_count} rows"
      else:
        status = "WARNING"
        message = "Data integrity check warning: your_key_table exists but has no data"
    else:
      status = "FAILED"
      message = "Data integrity check failed: your_key_table does not exist"
      
  except Exception as e:
    status = "FAILED"
    message = f"Error validating data integrity: {str(e)}"
  
  print(f"Result: {status} - {message}")
  return {"status": status, "message": message}

# Uncomment when ready to test with actual tables
# validation_results["tests"]["data_integrity"] = validate_data_integrity()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Summary and Results

# COMMAND ----------

# Calculate overall status
test_statuses = [test["status"] for test in validation_results["tests"].values()]
if "FAILED" in test_statuses:
  validation_results["overall_status"] = "FAILED"
elif "WARNING" in test_statuses:
  validation_results["overall_status"] = "WARNING"
else:
  validation_results["overall_status"] = "PASSED"

# Display results
print(f"DR Validation Results: {validation_results['overall_status']}")
print("-" * 80)
for test_name, result in validation_results["tests"].items():
  print(f"{test_name}: {result['status']} - {result['message']}")

# Save results to a Delta table for tracking
validation_results_df = spark.createDataFrame([validation_results])
validation_results_df.write.format("delta").mode("append").saveAsTable("dr_validation_results")

# COMMAND ----------

# Return results as JSON for programmatic use
import json
dbutils.notebook.exit(json.dumps(validation_results))