# Databricks cluster for inference workloads
resource "databricks_cluster" "inference_cluster" {
  cluster_name            = "${var.name}-inference"
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type_id
  autotermination_minutes = var.cluster_autotermination_minutes
  
  # Use single node cluster to reduce resource requirements
  num_workers = 0
  
  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
    "spark.databricks.repl.allowedLanguages" : "sql,python,r"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
    "Purpose"       = "Inference"
  }
}

# Databricks cluster for monitoring
resource "databricks_cluster" "monitoring_cluster" {
  cluster_name            = "${var.name}-monitoring"
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type_id
  autotermination_minutes = var.cluster_autotermination_minutes
  
  # Use single node cluster to reduce resource requirements
  num_workers = 0
  
  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
    "spark.databricks.repl.allowedLanguages" : "sql,python,r"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
    "Purpose"       = "Monitoring"
  }
}

# SQL Warehouse for inference tables - using serverless compute
resource "databricks_sql_endpoint" "inference_warehouse" {
  name                    = "${var.name}-inference-warehouse"
  cluster_size            = "2X-Small"  # Smallest available size
  auto_stop_mins          = var.sql_warehouse_auto_stop_mins
  
  # Use serverless compute instead of classic warehouses
  enable_serverless_compute = true
  
  # Use photon acceleration
  enable_photon          = true
  
  # Increase the timeout for warehouse creation
  warehouse_type         = "PRO"
  
  # Set spot instance policy to RELIABILITY_OPTIMIZED for more stable provisioning
  spot_instance_policy   = "RELIABILITY_OPTIMIZED"
  
  # Reduce the number of clusters to minimize resource requirements
  max_num_clusters       = 1
}

# SQL Warehouse for dashboards and monitoring - using serverless compute
resource "databricks_sql_endpoint" "dashboard_warehouse" {
  name                    = "${var.name}-dashboard-warehouse"
  cluster_size            = "2X-Small"  # Smallest available size
  auto_stop_mins          = var.sql_warehouse_auto_stop_mins
  
  # Use serverless compute instead of classic warehouses
  enable_serverless_compute = true
  
  # Use photon acceleration
  enable_photon          = true
  
  # Increase the timeout for warehouse creation
  warehouse_type         = "PRO"
  
  # Set spot instance policy to RELIABILITY_OPTIMIZED for more stable provisioning
  spot_instance_policy   = "RELIABILITY_OPTIMIZED"
  
  # Reduce the number of clusters to minimize resource requirements
  max_num_clusters       = 1
}