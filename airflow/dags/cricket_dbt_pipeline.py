from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="cricket_dbt_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule="*/30 * * * *",
    catchup=False,
    tags=["cricket", "snowflake", "dbt"],
) as dag:
    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command="cd /opt/airflow/cricket_dbt && dbt deps --profiles-dir .",
    )

    dbt_snapshot = BashOperator(
        task_id="player_scd2_snapshot",
        bash_command="cd /opt/airflow/cricket_dbt && dbt snapshot --profiles-dir .",
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd /opt/airflow/cricket_dbt && dbt build --profiles-dir .",
    )

    dbt_deps >> dbt_snapshot >> dbt_build
