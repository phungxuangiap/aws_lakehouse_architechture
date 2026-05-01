variable "image_tag" {
  type = string
  description = "Tag của Docker Image mới được build, sẽ được truyền vào từ Workflow để cập nhật Lambda"
  default = "value"
}
variable "glue_iam_role_name" {
  type        = string
  default     = "vg-glue-role"
}


variable "bronze_glue_database" {
  type        = string
  default     = "bronze"
}

variable "silver_glue_database" {
  type        = string
  default     = "silver"
}

variable "gold_glue_database" {
  type        = string
  default     = "gold"
}

variable "s3_location_bronze_glue_database" {
  type        = string
  default     = "s3://alex-lakehouse-storage-2026/bronze/"
} 
variable "s3_location_silver_glue_database" {
  type        = string
  default     = "s3://alex-lakehouse-storage-2026/silver/"
}
variable "s3_location_gold_glue_database" {
  type        = string
  default     = "s3://alex-lakehouse-storage-2026/gold/"  
}