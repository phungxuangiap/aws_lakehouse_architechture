variable "aws_region" {
  description = "AWS Region to deploy"
  type        = string
  default     = "ap-southeast-2"
}
variable "key_name" {
  type        = string
  default     = "app-key"
  description = "EC2 key name"
}
variable "airflow_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Airflow instance type ec2"
}