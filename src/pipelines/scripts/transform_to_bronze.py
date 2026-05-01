def main():
    print("Transforming data to bronze layer...")

if __name__ == "__main__":
    import os
    import sys

    # Thêm thư mục gốc của dự án vào sys.path để có thể import các module
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    sys.path.append(project_root)

    from pipelines.scripts.transform_to_bronze import main

    main()