variable "image_tag" {
  type = string
  description = "Tag của Docker Image mới được build, sẽ được truyền vào từ Workflow để cập nhật Lambda"
  default = "value"
}