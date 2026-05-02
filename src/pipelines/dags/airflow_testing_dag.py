from airflow.decorators import dag, task
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from datetime import datetime

# Cấu hình tập trung
GLUE_BUCKET = "alex-lakehouse-storage-2026"
GLUE_IAM_ROLE = "vg-glue-role" # Tên Role bạn đã tạo bên Terraform
REGION = "ap-southeast-2"

# Đường dẫn thư viện Delta Lake
DELTA_JAR_PATH = (
    f"s3://{GLUE_BUCKET}/delta_jar/delta-core_2.12-2.1.0.jar,"
    f"s3://{GLUE_BUCKET}/delta_jar/delta-storage-2.1.0.jar"
)

# Cấu hình mặc định cho tất cả các Glue Jobs
GLUE_CONF = {
    "GlueVersion": "4.0",
    "WorkerType": "G.1X",
    "NumberOfWorkers": 2,
    "DefaultArguments": {
        '--extra-jars': DELTA_JAR_PATH,
        '--extra-py-files': DELTA_JAR_PATH,
        '--enable-glue-datacatalog': 'true',
        # Thêm cấu hình Spark để nhận diện Delta Lake
        '--conf': 'spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog'
    },
}

@dag(
    dag_id='linkedin_lakehouse_pipeline_v1',
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["linkedin", "lakehouse"]
)
def lakehouse_dag():

    # 1. Tầng Bronze: Ingestion từ Landing sang Bronze (Delta format)
    bronze_task = GlueJobOperator(
        task_id="bronze_layer_job",
        job_name="linkedin_transform_bronze", # Tên job sẽ hiển thị trên AWS
        script_location=f"s3://{GLUE_BUCKET}/scripts/transform_to_bronze.py",
        iam_role_name=GLUE_IAM_ROLE,
        create_job_kwargs=GLUE_CONF,
        region_name=REGION,
        aws_conn_id="aws_default",
        wait_for_completion=True,
    )

    # # 2. Tầng Silver: Cleaning & Schema Enforcement
    # silver_task = GlueJobOperator(
    #     task_id="silver_layer_job",
    #     job_name="linkedin_transform_silver",
    #     script_location=f"s3://{GLUE_BUCKET}/scripts/transform_to_silver.py",
    #     iam_role_name=GLUE_IAM_ROLE,
    #     create_job_kwargs=GLUE_CONF,
    #     region_name=REGION,
    #     aws_conn_id="aws_default",
    #     wait_for_completion=True,
    # )

    # # 3. Tầng Gold: Aggregation cho Dashboard
    # gold_task = GlueJobOperator(
    #     task_id="gold_layer_job",
    #     job_name="linkedin_transform_gold",
    #     script_location=f"s3://{GLUE_BUCKET}/scripts/transform_to_gold.py",
    #     iam_role_name=GLUE_IAM_ROLE,
    #     create_job_kwargs=GLUE_CONF,
    #     region_name=REGION,
    #     aws_conn_id="aws_default",
    #     wait_for_completion=True,
    # )

    # # Thiết lập chuỗi thực thi: Bronze xong mới đến Silver, Silver xong mới đến Gold
    # bronze_task >> silver_task >> gold_task
    bronze_task
    

lakehouse_dag()