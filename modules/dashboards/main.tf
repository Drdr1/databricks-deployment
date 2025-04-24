locals {
  dashboard_queries_content = <<-EOT
# Create Dashboard Queries

# Cluster Performance Dashboard Query
%sql
CREATE OR REPLACE VIEW monitoring_db.v_cluster_performance AS
SELECT 
  cluster_id,
  date_trunc('hour', timestamp) as hour,
  avg(cpu_utilization) as avg_cpu,
  max(cpu_utilization) as max_cpu,
  avg(memory_utilization) as avg_memory,
  max(memory_utilization) as max_memory,
  avg(disk_utilization) as avg_disk,
  max(disk_utilization) as max_disk
FROM monitoring_db.cluster_metrics
WHERE timestamp > current_timestamp() - INTERVAL 7 DAYS
GROUP BY cluster_id, date_trunc('hour', timestamp)
ORDER BY hour DESC;

# Job Performance Dashboard Query
%sql
CREATE OR REPLACE VIEW monitoring_db.v_job_performance AS
SELECT 
  job_name,
  date_trunc('day', start_time) as day,
  count(*) as num_runs,
  avg(duration_ms)/1000 as avg_duration_seconds,
  max(duration_ms)/1000 as max_duration_seconds,
  sum(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful_runs,
  sum(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) as failed_runs
FROM monitoring_db.job_metrics
WHERE start_time > current_timestamp() - INTERVAL 30 DAYS
GROUP BY job_name, date_trunc('day', start_time)
ORDER BY day DESC;

# Query Performance Dashboard Query
%sql
CREATE OR REPLACE VIEW monitoring_db.v_query_performance AS
SELECT 
  warehouse_id,
  date_trunc('hour', start_time) as hour,
  count(*) as num_queries,
  avg(duration_ms)/1000 as avg_duration_seconds,
  percentile(duration_ms/1000, 0.95) as p95_duration_seconds,
  max(duration_ms)/1000 as max_duration_seconds,
  sum(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) as failed_queries
FROM monitoring_db.query_metrics
WHERE start_time > current_timestamp() - INTERVAL 7 DAYS
GROUP BY warehouse_id, date_trunc('hour', start_time)
ORDER BY hour DESC;
EOT

  create_dashboards_content = <<-EOT
# Create Dashboards using Databricks SQL API
import requests
import json
import os

# This would typically use Databricks SQL API to create dashboards
# For demonstration purposes, we're showing the structure

# Example dashboard definition
cluster_performance_dashboard = {
  "name": "Cluster Performance Dashboard",
  "dashboard_filters_enabled": True,
  "widgets": [
    {
      "visualization_id": "cluster_cpu_chart",
      "title": "Cluster CPU Utilization",
      "position": {"size_x": 6, "size_y": 4, "pos_x": 0, "pos_y": 0}
    },
    {
      "visualization_id": "cluster_memory_chart",
      "title": "Cluster Memory Utilization",
      "position": {"size_x": 6, "size_y": 4, "pos_x": 6, "pos_y": 0}
    },
    {
      "visualization_id": "cluster_disk_chart",
      "title": "Cluster Disk Utilization",
      "position": {"size_x": 12, "size_y": 4, "pos_x": 0, "pos_y": 4}
    }
  ]
}

job_performance_dashboard = {
  "name": "Job Performance Dashboard",
  "dashboard_filters_enabled": True,
  "widgets": [
    {
      "visualization_id": "job_success_rate",
      "title": "Job Success Rate",
      "position": {"size_x": 4, "size_y": 4, "pos_x": 0, "pos_y": 0}
    },
    {
      "visualization_id": "job_duration_trend",
      "title": "Job Duration Trend",
      "position": {"size_x": 8, "size_y": 4, "pos_x": 4, "pos_y": 0}
    },
    {
      "visualization_id": "job_runs_table",
      "title": "Recent Job Runs",
      "position": {"size_x": 12, "size_y": 6, "pos_x": 0, "pos_y": 4}
    }
  ]
}

query_performance_dashboard = {
  "name": "Query Performance Dashboard",
  "dashboard_filters_enabled": True,
  "widgets": [
    {
      "visualization_id": "query_duration_by_warehouse",
      "title": "Query Duration by Warehouse",
      "position": {"size_x": 6, "size_y": 4, "pos_x": 0, "pos_y": 0}
    },
    {
      "visualization_id": "query_failure_rate",
      "title": "Query Failure Rate",
      "position": {"size_x": 6, "size_y": 4, "pos_x": 6, "pos_y": 0}
    },
    {
      "visualization_id": "slow_queries_table",
      "title": "Slow Queries (P95)",
      "position": {"size_x": 12, "size_y": 6, "pos_x": 0, "pos_y": 4}
    }
  ]
}

print("Dashboard definitions created. In a real implementation, these would be created via API calls.")
EOT
}

resource "databricks_notebook" "dashboard_queries_setup" {
  path     = "/Shared/setup/dashboard_queries_setup"
  language = "PYTHON"
  content_base64 = base64encode(local.dashboard_queries_content)
}

# Run the dashboard queries setup
resource "databricks_job" "setup_dashboard_queries" {
  name = "Setup Dashboard Queries"
  
  new_cluster {
    num_workers   = 1
    spark_version = var.cluster_spark_version
    node_type_id  = var.cluster_node_type_id
  }
  
  # Use tasks instead of notebook_task
  task {
    task_key = "setup_dashboard_queries"
    notebook_task {
      notebook_path = databricks_notebook.dashboard_queries_setup.path
    }
  }
  
  email_notifications {}
}

# Create dashboard definitions notebook
resource "databricks_notebook" "create_dashboards" {
  path     = "/Shared/setup/create_dashboards"
  language = "PYTHON"
  content_base64   = base64encode(local.create_dashboards_content)
}

# Run the create dashboards notebook
resource "databricks_job" "create_dashboards_job" {
  name = "Create Dashboards"
  
  new_cluster {
    num_workers   = 1
    spark_version = var.cluster_spark_version
    node_type_id  = var.cluster_node_type_id
  }
  
  # Use tasks instead of notebook_task
  task {
    task_key = "create_dashboards"
    notebook_task {
      notebook_path = databricks_notebook.create_dashboards.path
    }
  }
  
  email_notifications {}
}