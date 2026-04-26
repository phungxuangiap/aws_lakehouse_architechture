terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Cấu hình backend để lưu state file trên S3, giúp team có thể làm việc chung và tránh xung đột
  backend "s3" {
    bucket         = "giap-n23dcat018-tfstate-080625" 
    key            = "core/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 1. ECR REPOSITORY (Nơi chứa Docker Image) ---
resource "aws_ecr_repository" "data_pipeline_repo" {
  name                 = "alex-data-pipeline"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true # Cho phép xóa repo ngay cả khi có image bên trong
}

# --- 2. S3 BUCKETS (lakehouse: Bronze, Silver, Gold) ---
# Ở đây tôi ví dụ tạo 1 bucket chung, bạn có thể chia nhỏ folder bên trong
resource "aws_s3_bucket" "lakehouse" {   
  bucket        = "alex-lakehouse-storage-2026"   
  force_destroy = true                    
}    
  
# Bật tính năng versioning để bảo vệ dữ liệu
resource "aws_s3_bucket_versioning" "datalake_versioning" {
  bucket = aws_s3_bucket.lakehouse.id
  versioning_configuration {
    status = "Enabled"
  }
}  
# --- 1. IAM ROLE CHO LAMBDA ---
resource "aws_iam_role" "lambda_exec_role" {
  name = "alex_lambda_ecr_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
    

# --- OUTPUTS (Để phần App có thể lấy thông tin) ---
output "ecr_repository_url" {
  value = aws_ecr_repository.data_pipeline_repo.repository_url
}
output "ecr_repository_name" {
  value = aws_ecr_repository.data_pipeline_repo.name
}
output "s3_bucket_name" {
  value = aws_s3_bucket.lakehouse.bucket
}
output "lambda_exec_role_name" {
  value = aws_iam_role.lambda_exec_role.name
}
output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}