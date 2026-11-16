terraform {
  required_version = ">= 1.5.0"
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87.0"
    }
  }
}

provider "snowflake" {
  account  = var.snowflake_account
  user     = var.snowflake_user
  password = var.snowflake_password
  role     = var.snowflake_admin_role
}

# ---------------------------------------------------------------------------------------------------------------------
# WAREHOUSE CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
resource "snowflake_warehouse" "compute_wh" {
  name           = var.warehouse_name
  warehouse_size = "xsmall"
  auto_suspend   = 60
  auto_resume    = true
  initially_suspended = true
  comment        = "Compute warehouse for dbt models and raw ingestion orchestration."
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABASE & SCHEMAS (MEDALLION ARCHITECTURE)
# ---------------------------------------------------------------------------------------------------------------------
resource "snowflake_database" "mds_db" {
  name    = var.database_name
  comment = "Enterprise Modern Data Stack Data Warehouse"
}

resource "snowflake_schema" "raw_schema" {
  database = snowflake_database.mds_db.name
  name     = "RAW"
  comment  = "Bronze layer for raw landed JSON/NDJSON payloads."
}

resource "snowflake_schema" "staging_schema" {
  database = snowflake_database.mds_db.name
  name     = "STAGING"
  comment  = "Silver layer for deduplicated, typed views."
}

resource "snowflake_schema" "analytics_schema" {
  database = snowflake_database.mds_db.name
  name     = "ANALYTICS"
  comment  = "Gold layer for business marts, dimensions, and facts."
}

# ---------------------------------------------------------------------------------------------------------------------
# ROLES & RBAC PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------
resource "snowflake_role" "data_engineer_role" {
  name    = "DATA_ENGINEER"
  comment = "Role for Airflow orchestration and dbt transformation pipelines."
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  privileges        = ["USAGE", "OPERATE"]
  account_role_name = snowflake_role.data_engineer_role.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.compute_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  privileges        = ["USAGE", "CREATE SCHEMA"]
  account_role_name = snowflake_role.data_engineer_role.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.mds_db.name
  }
}
