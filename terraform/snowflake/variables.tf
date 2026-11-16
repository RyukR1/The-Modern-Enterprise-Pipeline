variable "snowflake_account" {
  description = "Snowflake account identifier (e.g. xy12345.us-east-1)."
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake administrator username."
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake administrator password."
  type        = string
  sensitive   = true
}

variable "snowflake_admin_role" {
  description = "Administrative role used to provision infrastructure."
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "database_name" {
  description = "Snowflake target database name."
  type        = string
  default     = "ENTERPRISE_MDS"
}

variable "warehouse_name" {
  description = "Snowflake compute warehouse name."
  type        = string
  default     = "COMPUTE_WH"
}
