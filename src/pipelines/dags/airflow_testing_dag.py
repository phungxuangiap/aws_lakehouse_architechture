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
    def call_external_file():
        script_path = "/opt/airflow/scripts/transform_to_bronze.py"
        result = subprocess.run(['python3', script_path], capture_output=True, text=True)
        
        print("Output của script:")
        print(result.stdout) # In ra màn hình log của Airflow
        
        if result.returncode != 0:
            raise Exception(f"Script lỗi: {result.stderr}")

    call_external_file()

script_dag = script_test_flow()