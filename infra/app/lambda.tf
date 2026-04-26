# Đọc outputs từ core infrastructure
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "giap-n23dcat018-tfstate-080625"
    key    = "core/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

# Gắn policy cơ bản để Lambda có thể đẩy log lên CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = data.terraform_remote_state.core.outputs.lambda_exec_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# QUAN TRỌNG: Quyền để Lambda có thể Pull Image từ ECR
resource "aws_iam_role_policy_attachment" "lambda_ecr_pull" {
  role       = data.terraform_remote_state.core.outputs.lambda_exec_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" 
  # Hoặc dùng AmazonEC2ContainerRegistryReadOnly nếu không chạy trong VPC
}

# --- 2. LAMBDA FUNCTION (Sử dụng Image từ ECR) ---
resource "aws_lambda_function" "data_pipeline_lambda" {
  function_name = "alex-ingestion-worker"
  role          = data.terraform_remote_state.core.outputs.lambda_exec_role_arn
  
  # Chỉ định sử dụng Docker Image thay vì file .zip
  package_type  = "Image"
  
  # Image URI được truyền vào từ biến image_tag trong Workflow
  image_uri     = "${data.terraform_remote_state.core.outputs.ecr_repository_url}:${var.image_tag}"

  timeout       = 300 # 5 phút
  memory_size   = 512

  environment {
    variables = {
      ENV = "production"
      S3_BUCKET = data.terraform_remote_state.core.outputs.s3_bucket_name
      ECR_REPOSITORY_URL = data.terraform_remote_state.core.outputs.ecr_repository_url
    }
  }
}

# --- 3. EVENTBRIDGE (Trigger theo lịch trình, ví dụ: mỗi 1 tiếng) ---
resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "alex-trigger-every-hour"
  description         = "Kích hoạt Lambda xử lý data mỗi giờ"
  schedule_expression = "rate(1 hour)"
}

# Thiết lập mục tiêu (Target) cho EventBridge là con Lambda ở trên
resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule           = aws_cloudwatch_event_rule.every_hour.name
  target_id      = "DataPipelineLambda"
  arn            = aws_lambda_function.data_pipeline_lambda.arn
}

# --- 4. CẤP QUYỀN CHO EVENTBRIDGE GỌI LAMBDA ---
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_pipeline_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}