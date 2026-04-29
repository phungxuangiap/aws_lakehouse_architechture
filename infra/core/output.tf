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
output "lambda_s3_policy_arn" {
  value = aws_iam_policy.lambda_s3_policy.arn
}
output "lambda_s3_policy_name" {
  value = aws_iam_policy.lambda_s3_policy.name
}
output "ec2_private_key" {
  description = "EC2 private key"
  value       = tls_private_key.custom_key.private_key_pem
  sensitive   = true
}
output "ec2_public_key" {
  description = "EC2 public key"
  value       = aws_key_pair.generated_key.public_key
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.airflow_ec2.public_ip  
}
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.airflow_ec2.id
}