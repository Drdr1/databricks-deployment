locals {
  create_inference_database_content = <<-EOT
# Create Inference Database
%sql
CREATE DATABASE IF NOT EXISTS inference_db
COMMENT 'Database for ML inference tables';

# Create example inference table
%sql
CREATE TABLE IF NOT EXISTS inference_db.model_predictions (
  prediction_id STRING,
  model_name STRING,
  input_data STRING,
  prediction_result STRING,
  prediction_timestamp TIMESTAMP,
  confidence_score DOUBLE,
  execution_time_ms LONG
)
USING DELTA
COMMENT 'Table for storing model predictions';

# Create example model registry table
%sql
CREATE TABLE IF NOT EXISTS inference_db.model_registry (
  model_id STRING,
  model_name STRING,
  model_version STRING,
  created_timestamp TIMESTAMP,
  status STRING,
  metrics STRING,
  description STRING
)
USING DELTA
COMMENT 'Table for tracking model versions';
EOT
}

# Create a catalog for inference tables if Unity Catalog is enabled
resource "databricks_catalog" "inference_catalog" {
  count      = var.enable_unity_catalog ? 1 : 0
  name       = "inference_catalog"
  comment    = "Catalog for inference tables"
  properties = {
    purpose = "ML inference"
  }
}

# Create a schema for inference tables
resource "databricks_schema" "inference_schema" {
  count     = var.enable_unity_catalog ? 1 : 0
  name      = "inference_schema"
  catalog_name = databricks_catalog.inference_catalog[0].name
  comment   = "Schema for inference tables"
  properties = {
    purpose = "ML inference"
  }
}

# Create a volume for storing inference data if Unity Catalog is enabled
resource "databricks_volume" "inference_volume" {
  count = var.enable_unity_catalog && var.unity_catalog_metastore_id != null ? 1 : 0
  name = "inference_volume"
  catalog_name = databricks_catalog.inference_catalog[0].name
  schema_name = databricks_schema.inference_schema[0].name
  volume_type = "EXTERNAL"
  comment = "Volume for storing inference data"
}

# For non-Unity Catalog setups, create a database
resource "databricks_notebook" "create_inference_database" {
  count    = var.enable_unity_catalog ? 0 : 1
  path     = "/Shared/setup/create_inference_database"
  language = "PYTHON"
  content_base64 =  base64encode(local.create_inference_database_content)
}

# Run the notebook to create the database and tables
resource "databricks_job" "setup_inference_db" {
  count = var.enable_unity_catalog ? 0 : 1
  name = "Setup Inference Database"
  
  new_cluster {
    num_workers   = 1
    spark_version = var.cluster_spark_version
    node_type_id  = var.cluster_node_type_id
  }
  
  # Use tasks instead of notebook_task
  task {
    task_key = "setup_inference_db"
    notebook_task {
      notebook_path = databricks_notebook.create_inference_database[0].path
    }
  }
  
  email_notifications {}
}