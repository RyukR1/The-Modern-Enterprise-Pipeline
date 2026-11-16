output "snowflake_warehouse" {
  description = "Provisioned Snowflake warehouse name."
  value       = snowflake_warehouse.compute_wh.name
}

output "snowflake_database" {
  description = "Provisioned Snowflake database name."
  value       = snowflake_database.mds_db.name
}

output "snowflake_role" {
  description = "Provisioned Data Engineer role."
  value       = snowflake_role.data_engineer_role.name
}
