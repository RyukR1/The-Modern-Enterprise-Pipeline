import os
import logging
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)


class SnowflakeStageLoader:
    """
    Utility class for loading files into Snowflake External/Internal Stages
    and executing COPY INTO statements for raw data ingestion.
    """

    def __init__(
        self,
        snowflake_conn_id: str = "snowflake_default",
        account: Optional[str] = None,
        user: Optional[str] = None,
        password: Optional[str] = None,
        warehouse: Optional[str] = None,
        database: Optional[str] = None,
        schema: Optional[str] = None,
        role: Optional[str] = None,
    ):
        self.snowflake_conn_id = snowflake_conn_id
        self.account = account or os.getenv("SNOWFLAKE_ACCOUNT")
        self.user = user or os.getenv("SNOWFLAKE_USER")
        self.password = password or os.getenv("SNOWFLAKE_PASSWORD")
        self.warehouse = warehouse or os.getenv("SNOWFLAKE_WAREHOUSE", "INGEST_WH")
        self.database = database or os.getenv("SNOWFLAKE_DATABASE", "RAW_DB")
        self.schema = schema or os.getenv("SNOWFLAKE_SCHEMA", "BRONZE")
        self.role = role or os.getenv("SNOWFLAKE_ROLE", "DATA_ENGINEER")

    def get_connection(self):
        """
        Retrieves active Snowflake connection via Airflow SnowflakeHook or connector fallback.
        """
        try:
            from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
            hook = SnowflakeHook(snowflake_conn_id=self.snowflake_conn_id)
            return hook.get_conn()
        except Exception as e:
            logger.warning(f"Could not load Airflow SnowflakeHook ({e}), attempting direct connector connection.")
            import snowflake.connector
            return snowflake.connector.connect(
                user=self.user,
                password=self.password,
                account=self.account,
                warehouse=self.warehouse,
                database=self.database,
                schema=self.schema,
                role=self.role,
            )

    def upload_to_stage(self, local_filepath: str, stage_name: str) -> None:
        """
        PUT local file into Snowflake internal stage.
        """
        put_sql = f"PUT file://{local_filepath} @{stage_name} AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
        logger.info(f"Executing PUT to stage: {stage_name}")

        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute(put_sql)
                logger.info(f"File {local_filepath} successfully staged to @{stage_name}")
        finally:
            conn.close()

    def copy_stage_to_raw_table(
        self,
        table_name: str,
        stage_name: str,
        file_pattern: Optional[str] = None,
        file_type: str = "JSON",
    ) -> int:
        """
        Execute COPY INTO statement from Stage to Snowflake Raw Table.
        """
        pattern_clause = f"PATTERN = '{file_pattern}'" if file_pattern else ""
        copy_sql = f"""
        COPY INTO {self.database}.{self.schema}.{table_name} (raw_payload, ingested_at)
        FROM (
            SELECT $1, CURRENT_TIMESTAMP()
            FROM @{stage_name}
        )
        FILE_FORMAT = (TYPE = '{file_type}' STRIP_OUTER_ARRAY = TRUE MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE)
        {pattern_clause}
        ON_ERROR = 'CONTINUE';
        """
        logger.info(f"Executing COPY INTO SQL:\n{copy_sql}")

        conn = self.get_connection()
        rows_loaded = 0
        try:
            with conn.cursor() as cursor:
                cursor.execute(copy_sql)
                results = cursor.fetchall()
                for row in results:
                    logger.info(f"COPY Status: file={row[0]}, status={row[1]}, rows_loaded={row[2]}")
                    if len(row) > 2 and isinstance(row[2], int):
                        rows_loaded += row[2]
        finally:
            conn.close()

        return rows_loaded
