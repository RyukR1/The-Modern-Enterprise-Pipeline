import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

from dags.utils.alert_callbacks import slack_failure_callback

# dbt Project Path configuration
DBT_PROJECT_PATH = os.getenv("DBT_PROJECT_PATH", "/usr/local/airflow/dbt_project")
DBT_EXECUTABLE_PATH = os.getenv("DBT_EXECUTABLE_PATH", "/usr/local/bin/dbt")

default_args = {
    "owner": "data_engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": slack_failure_callback,
}

try:
    # Attempt to import Astronomer Cosmos for native dbt DAG orchestration
    from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig
    from cosmos.profiles import SnowflakeUserPasswordProfileMapping, DuckDBUserPasswordProfileMapping

    HAS_COSMOS = True
except ImportError:
    HAS_COSMOS = False

with DAG(
    dag_id="dbt_cosmos_transform_dag",
    default_args=default_args,
    description="Orchestrates dbt Silver & Gold transformation models using Astronomer Cosmos.",
    schedule_interval="0 5 * * *",  # Daily at 05:00 UTC
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["dbt", "transform", "cosmos", "snowflake", "gold"],
) as dag:

    if HAS_COSMOS and os.path.exists(DBT_PROJECT_PATH):
        profile_config = ProfileConfig(
            profile_name="enterprise_mds",
            target_name=os.getenv("DBT_TARGET", "dev"),
            profiles_yml_filepath=os.path.join(DBT_PROJECT_PATH, "profiles.yml"),
        )

        dbt_transform_group = DbtTaskGroup(
            group_id="dbt_transformation_pipeline",
            project_config=ProjectConfig(DBT_PROJECT_PATH),
            profile_config=profile_config,
            execution_config=ExecutionConfig(dbt_executable_path=DBT_EXECUTABLE_PATH),
        )
    else:
        # Fallback BashOperator execution if Cosmos is running in basic Airflow container environment
        dbt_deps = BashOperator(
            task_id="dbt_deps",
            bash_command=f"cd {DBT_PROJECT_PATH} && dbt deps --profiles-dir .",
        )

        dbt_seed = BashOperator(
            task_id="dbt_seed",
            bash_command=f"cd {DBT_PROJECT_PATH} && dbt seed --profiles-dir .",
        )

        dbt_snapshot = BashOperator(
            task_id="dbt_snapshot",
            bash_command=f"cd {DBT_PROJECT_PATH} && dbt snapshot --profiles-dir .",
        )

        dbt_run = BashOperator(
            task_id="dbt_run",
            bash_command=f"cd {DBT_PROJECT_PATH} && dbt run --profiles-dir .",
        )

        dbt_test = BashOperator(
            task_id="dbt_test",
            bash_command=f"cd {DBT_PROJECT_PATH} && dbt test --profiles-dir .",
        )

        dbt_deps >> dbt_seed >> dbt_snapshot >> dbt_run >> dbt_test
