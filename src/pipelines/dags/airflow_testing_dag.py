from airflow.decorators import dag
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from datetime import datetime

@dag(
    dag_id='run_script_functional',
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False
)
def script_test_flow():

    # Thay vì dùng subprocess, ta dùng Operator chuyên dụng của AWS
    transform_data_to_bronze = GlueJobOperator(
        task_id="transform_data_to_bronze",
        job_name="linkedin_transform_bronze", # Tên Job đã tạo trên AWS Glue
        script_location="s3://your-bucket-name/scripts/transform_to_bronze.py", # Script phải nằm trên S3
        aws_conn_id="aws_default",
        region_name="ap-southeast-2",
        wait_for_completion=True
    )

script_dag = script_test_flow()