import os
import logging
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

from dags.utils.api_client import APIClient
from dags.utils.snowflake_hooks import SnowflakeStageLoader
from dags.utils.alert_callbacks import slack_failure_callback, discord_failure_callback

logger = logging.getLogger(__name__)

# Default arguments for Airflow tasks
default_args = {
    "owner": "data_engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=3),
    "on_failure_callback": slack_failure_callback,
}

# Define the DAG
with DAG(
    dag_id="raw_api_ingestion_dag",
    default_args=default_args,
    description="Ingests raw events and users from REST API into S3/MinIO and loads into Snowflake RAW schema.",
    schedule_interval="0 */4 * * *",  # Every 4 hours
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["ingestion", "raw", "api", "snowflake"],
) as dag:

    def extract_and_upload_api_data(**kwargs):
        """
        Extract users and events from API client, write to local NDJSON, and upload to S3/MinIO.
        """
        execution_date = kwargs.get("ds", datetime.utcnow().strftime("%Y-%m-%d"))
        api_base_url = os.getenv("API_BASE_URL", "https://jsonplaceholder.typicode.com")

        client = APIClient(base_url=api_base_url)

        # Extract API payload datasets
        logger.info("Extracting users from API...")
        users = client.fetch_paginated("users", page_size=10, max_pages=5)

        logger.info("Extracting events from API...")
        events = client.fetch_paginated("posts", page_size=20, max_pages=5)

        tmp_dir = "/tmp/ingestion"
        os.makedirs(tmp_dir, exist_ok=True)

        users_file = os.path.join(tmp_dir, f"users_{execution_date}.json")
        events_file = os.path.join(tmp_dir, f"events_{execution_date}.json")

        client.save_as_ndjson(users, users_file)
        client.save_as_ndjson(events, events_file)

        # Upload to MinIO / S3
        s3_bucket = os.getenv("S3_BUCKET_NAME", "raw-data")

        try:
            s3_hook = S3Hook(aws_conn_id="aws_default")
            s3_hook.load_file(
                filename=users_file,
                key=f"raw/users/date={execution_date}/users.json",
                bucket_name=s3_bucket,
                replace=True,
            )
            s3_hook.load_file(
                filename=events_file,
                key=f"raw/events/date={execution_date}/events.json",
                bucket_name=s3_bucket,
                replace=True,
            )
            logger.info("Successfully uploaded API payloads to S3 storage bucket.")
        except Exception as e:
            logger.warning(f"S3Hook upload fallback: {e}. Staging files locally for Snowflake PUT.")

        kwargs["ti"].xcom_push(key="users_file", value=users_file)
        kwargs["ti"].xcom_push(key="events_file", value=events_file)

    def load_raw_into_snowflake(**kwargs):
        """
        Copies staged JSON payloads into Snowflake RAW tables.
        """
        ti = kwargs["ti"]
        users_file = ti.xcom_pull(key="users_file", task_ids="extract_and_upload_api_data")
        events_file = ti.xcom_pull(key="events_file", task_ids="extract_and_upload_api_data")

        loader = SnowflakeStageLoader()

        if users_file and os.path.exists(users_file):
            logger.info("Uploading users payload into Snowflake Stage...")
            loader.upload_to_stage(users_file, "RAW_S3_STAGE/users/")
            loader.copy_stage_to_raw_table(
                table_name="RAW_USERS",
                stage_name="RAW_S3_STAGE/users/",
                file_type="JSON",
            )

        if events_file and os.path.exists(events_file):
            logger.info("Uploading events payload into Snowflake Stage...")
            loader.upload_to_stage(events_file, "RAW_S3_STAGE/events/")
            loader.copy_stage_to_raw_table(
                table_name="RAW_EVENTS",
                stage_name="RAW_S3_STAGE/events/",
                file_type="JSON",
            )

    extract_task = PythonOperator(
        task_id="extract_and_upload_api_data",
        python_callable=extract_and_upload_api_data,
        provide_context=True,
    )

    load_snowflake_task = PythonOperator(
        task_id="load_raw_into_snowflake",
        python_callable=load_raw_into_snowflake,
        provide_context=True,
    )

    extract_task >> load_snowflake_task
