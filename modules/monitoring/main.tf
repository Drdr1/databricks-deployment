locals {
  monitoring_setup_content = <<-EOT
# Create Monitoring Database
%sql
CREATE DATABASE IF NOT EXISTS monitoring_db
COMMENT 'Database for Databricks monitoring';

# Create cluster monitoring table
%sql
CREATE TABLE IF NOT EXISTS monitoring_db.cluster_metrics (
  cluster_id STRING,
  timestamp TIMESTAMP,
  driver_status STRING,
  worker_status STRING,
  num_workers INT,
  cpu_utilization DOUBLE,
  memory_utilization DOUBLE,
  disk_utilization DOUBLE
)
USING DELTA
PARTITIONED BY (date(timestamp))
COMMENT 'Table for storing cluster performance metrics';

# Create job monitoring table
%sql
CREATE TABLE IF NOT EXISTS monitoring_db.job_metrics (
  job_id STRING,
  run_id STRING,
  job_name STRING,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status STRING,
  duration_ms LONG,
  error_message STRING
)
USING DELTA
PARTITIONED BY (date(start_time))
COMMENT 'Table for storing job execution metrics';

# Create query monitoring table
%sql
CREATE TABLE IF NOT EXISTS monitoring_db.query_metrics (
  query_id STRING,
  warehouse_id STRING,
  user_name STRING,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  duration_ms LONG,
  status STRING,
  error_message STRING,
  query_text STRING
)
USING DELTA
PARTITIONED BY (date(start_time))
COMMENT 'Table for storing SQL query metrics';
EOT

  collect_monitoring_data_content = <<-EOT
# Databricks Monitoring Data Collection
import datetime
import json
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Get current timestamp
current_time = datetime.datetime.now()

# Example: Collect cluster metrics
# In a real implementation, you would use the Databricks API to collect this data
cluster_metrics_data = [
  {
    "cluster_id": "{{dbutils.notebook.entry_point.getDbutils().notebook().getContext().clusterId().get()}}",
    "timestamp": current_time,
    "driver_status": "running",
    "worker_status": "running",
    "num_workers": spark.conf.get("spark.databricks.clusterUsageTags.clusterWorkers"),
    "cpu_utilization": 0.45,  # Example value
    "memory_utilization": 0.62,  # Example value
    "disk_utilization": 0.30  # Example value
  }
]

# Convert to DataFrame and write to monitoring table
cluster_metrics_df = spark.createDataFrame(cluster_metrics_data)
cluster_metrics_df.write.format("delta").mode("append").saveAsTable("monitoring_db.cluster_metrics")

print("Monitoring data collected successfully")
EOT
}

resource "databricks_notebook" "monitoring_setup" {
  path     = "/Shared/setup/monitoring_setup"
  language = "PYTHON"
  content_base64 =  base64encode(local.monitoring_setup_content)
}

resource "databricks_notebook" "collect_monitoring_data" {
  path     = "/Shared/monitoring/collect_monitoring_data"
  language = "PYTHON"
  content_base64 = base64encode(local.collect_monitoring_data_content)
}

# Create a job to run the monitoring data collection
resource "databricks_job" "monitoring_job" {
  name = "Collect Monitoring Data"
  
  schedule {
    quartz_cron_expression = "0 */15 * * * ?" # Run every 15 minutes
    timezone_id = "UTC"
  }
  
  new_cluster {
    num_workers   = 1
    spark_version = var.cluster_spark_version
    node_type_id  = var.cluster_node_type_id
  }
  
  # Use tasks instead of notebook_task
  task {
    task_key = "collect_monitoring_data"
    notebook_task {
      notebook_path = databricks_notebook.collect_monitoring_data.path
    }
  }
  
  email_notifications {}
}

# Run the setup notebook once
resource "databricks_job" "setup_monitoring" {
  name = "Setup Monitoring Database"
  
  new_cluster {
    num_workers   = 1
    spark_version = var.cluster_spark_version
    node_type_id  = var.cluster_node_type_id
  }
  
  # Use tasks instead of notebook_task
  task {
    task_key = "setup_monitoring"
    notebook_task {
      notebook_path = databricks_notebook.monitoring_setup.path
    }
  }
  
  email_notifications {}
}