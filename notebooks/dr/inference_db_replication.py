# Databricks notebook source
# MAGIC %md
# MAGIC # Inference Database Replication for DR
# MAGIC 
# MAGIC This notebook handles the replication of data from the production inference_db to the DR environment.
# MAGIC The process follows these steps:
# MAGIC 1. Export tables from production inference_db to Azure Blob Storage
# MAGIC 2. Set up a scheduled job to run this export regularly
# MAGIC 3. Create a corresponding import job in the DR environment

# COMMAND ----------

# MAGIC %md
# MAGIC ## Configuration

# COMMAND ----------

# Environment configuration
is_dr_env = dbutils.widgets.get("is_dr_env", "false").lower() == "true"
storage_account_name = "stgdatabricksdr"
storage_container_name = "inference-db-backup"
checkpoint_path = f"abfss://{storage_container_name}@{storage_account_name}.dfs.core.windows.net/checkpoints"
data_path = f"abfss://{storage_container_name}@{storage_account_name}.dfs.core.windows.net/data"

# Database configuration
source_db_name = "inference_db"
tables_to_replicate = [
  "predictions",
  "model_metrics",
  "feature_store",
  # Add all tables that need to be replicated
]

# COMMAND ----------

# MAGIC %md
# MAGIC ## Mount Storage if not already mounted

# COMMAND ----------

def mount_storage():
  """Mount the Azure Blob Storage container if not already mounted"""
  
  # Check if already mounted
  for mount in dbutils.fs.mounts():
    if mount.mountPoint == f"/mnt/{storage_container_name}":
      print(f"Storage already mounted at {mount.mountPoint}")
      return
  
  # Mount storage
  configs = {
    "fs.azure.account.auth.type": "OAuth",
    "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id": dbutils.secrets.get(scope="databricks-dr", key="storage-client-id"),
    "fs.azure.account.oauth2.client.secret": dbutils.secrets.get(scope="databricks-dr", key="storage-client-secret"),
    "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{dbutils.secrets.get(scope='databricks-dr', key='tenant-id')}/oauth2/token"
  }
  
  dbutils.fs.mount(
    source = f"abfss://{storage_container_name}@{storage_account_name}.dfs.core.windows.net",
    mount_point = f"/mnt/{storage_container_name}",
    extra_configs = configs
  )
  
  print(f"Storage mounted at /mnt/{storage_container_name}")

# Mount storage
mount_storage()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Export Data (Production Environment)

# COMMAND ----------

def export_table(table_name):
  """Export a table to Azure Blob Storage using Delta format"""
  if is_dr_env:
    print(f"Skipping export in DR environment for table: {table_name}")
    return
  
  print(f"Exporting table: {table_name}")
  
  # Read the source table
  source_table = spark.table(f"{source_db_name}.{table_name}")
  
  # Write to storage in Delta format with merge schema enabled
  (source_table.write
    .format("delta")
    .option("mergeSchema", "true")
    .mode("overwrite")
    .save(f"{data_path}/{table_name}"))
  
  print(f"Export completed for table: {table_name}")

# COMMAND ----------

# Only run export in production environment
if not is_dr_env:
  for table in tables_to_replicate:
    export_table(table)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Import Data (DR Environment)

# COMMAND ----------

def import_table(table_name):
  """Import a table from Azure Blob Storage in the DR environment"""
  if not is_dr_env:
    print(f"Skipping import in production environment for table: {table_name}")
    return
  
  print(f"Importing table: {table_name}")
  
  # Create database if it doesn't exist
  spark.sql(f"CREATE DATABASE IF NOT EXISTS {source_db_name}")
  
  # Read from storage
  imported_data = spark.read.format("delta").load(f"{data_path}/{table_name}")
  
  # Write to table
  (imported_data.write
    .format("delta")
    .option("mergeSchema", "true")
    .mode("overwrite")
    .saveAsTable(f"{source_db_name}.{table_name}"))
  
  print(f"Import completed for table: {table_name}")

# COMMAND ----------

# Only run import in DR environment
if is_dr_env:
  for table in tables_to_replicate:
    import_table(table)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Schedule Replication

# COMMAND ----------

# This part is for documentation purposes
# The actual scheduling is done through the Databricks Jobs UI or API

"""
To schedule this notebook:

1. In Production environment:
   - Create a job that runs this notebook with parameter is_dr_env=false
   - Schedule to run hourly to meet RPO requirements
   
2. In DR environment:
   - Create a job that runs this notebook with parameter is_dr_env=true
   - Schedule to run hourly, slightly after the production job (e.g., 15 minutes later)
   
This ensures data is first exported from production and then imported to DR.
"""

# COMMAND ----------

# Return success status
dbutils.notebook.exit("SUCCESS")