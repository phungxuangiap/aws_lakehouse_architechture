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
    bucket         = "alex-terraform-state" 
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
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
    
# --- 3. EVENTBRIDGE (Event Bus) ---
# Thường Lambda dùng Default Bus, nhưng tạo Custom Bus sẽ giúp bạn quản lý tốt hơn
resource "aws_cloudwatch_event_bus" "pipeline_bus" {
  name = "data-pipeline-bus"
}

# --- OUTPUTS (Để phần App có thể lấy thông tin) ---
output "ecr_repository_url" {
  value = aws_ecr_repository.data_pipeline_repo.repository_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.lakehouse.bucket
}

output "event_bus_name" {
  value = aws_cloudwatch_event_bus.pipeline_bus.name
}