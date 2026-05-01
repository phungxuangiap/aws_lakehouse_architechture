from airflow.decorators import dag
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from datetime import datetime
glue_bucket = "alex-lakehouse-storage-2026"
bronze_glue_job = "bronze-layer-job"
bronze_glue_job_key = "transform_to_bronze.py"
silver_glue_job = "silver-layer-job"
silver_glue_job_key = "transform_to_silver.py"
gold_glue_job = "gold-layer-job"
gold_glue_job_key = "transform_to_gold.py"
glue_iam_role = "vg-glue-role"
delta_path = "s3://alex-lakehouse-storage-2026/delta_jar/delta-core_2.12-2.1.0.jar,s3://alex-lakehouse-storage-2026/delta_jar/delta-storage-2.1.0.jar"
glue_args = {
    "GlueVersion": "4.0",
    "WorkerType": "G.1X",
    "NumberOfWorkers": 2,
    "DefaultArguments": {
        '--extra-jars': delta_path,
        '--extra-py-files': delta_path,
        '--enable-glue-datacatalog': 'true',
    },
}


glue_script_directory = "/opt/airflow/dags/glue-spark"
@dag(
    dag_id='run_script_functional',
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False
)
def lakehouse_dag():
    submit_glue_bronze_job = GlueJobOperator(
        task_id="bronze-layer-job",
        job_name="linkedin_transform_bronze",
        script_location=f"s3://{glue_bucket}/scripts/{bronze_glue_job_key}",
        # Sử dụng tên Role từ Terraform
        iam_role_name="vg-glue-role",
        # Áp dụng bộ cấu hình args ở trên
        create_job_kwargs=glue_args,
        region_name="ap-southeast-2",
        aws_conn_id="aws_default", # Sẽ tự động lấy từ .env đã cấu hình
        wait_for_completion=True,
    )
    submit_glue_bronze_job

lakehouse_dag = lakehouse_dag()