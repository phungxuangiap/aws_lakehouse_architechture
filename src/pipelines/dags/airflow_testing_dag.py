import subprocess
from airflow.decorators import dag, task
from datetime import datetime

@dag(
    dag_id='run_script_functional',
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False
)
def script_test_flow():

    @task
    def transform_data_to_bronze():
        script_path = "/opt/airflow/scripts/transform_to_bronze.py"
        result = subprocess.run(['python3', script_path], capture_output=True, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Failed to transform data to bronze layer: {result.stderr}")
        else:
            print(f"Data transformation to bronze layer completed successfully: {result.stdout}")
    transform_data_to_bronze()

script_dag = script_test_flow()