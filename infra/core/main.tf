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
        Service = ["lambda.amazonaws.com", "glue.amazonaws.com"]
      }
    }]
  })
}
    
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "alex_lambda_s3_write_policy"
  description = "Cho phép ghi dữ liệu vào Lakehouse S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::alex-lakehouse-storage-2026/*"
      },
      {
        # Nên thêm quyền ghi Log để bạn còn xem được log trên CloudWatch
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
resource "aws_security_group" "airflow_security_group" {
  name        = "airflow_security_group"
  description = "Security group to allow ssh and airflow"

  ingress {
    description = "Inbound SCP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "Inbound SCP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
    name   = "virtualization-type"
    values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}
resource "tls_private_key" "custom_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}


resource "aws_key_pair" "generated_key" {
    key_name   = var.key_name
    public_key = tls_private_key.custom_key.public_key_openssh
}



resource "aws_instance" "airflow_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.airflow_instance_type

  # THÊM DÒNG NÀY ĐỂ CÓ IP TRUY CẬP TỪ INTERNET
  associate_public_ip_address = true 

  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.airflow_security_group.id]

  tags = {
    Name = "airflow_glue"
  }

  user_data = <<EOF
#!/bin/bash
echo "-------------------------START SETUP---------------------------"
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg lsb-release unzip

# Cài đặt Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo chmod 666 /var/run/docker.sock

# CÀI ĐẶT AWS CLI (Để GitHub Action có thể Login ECR sau này)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

echo "-------------------------END SETUP---------------------------"
EOF
}
