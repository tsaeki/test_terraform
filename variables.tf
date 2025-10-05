# ECS Variables
variable "ecs_task_cpu" {
  description = "The amount of CPU to reserve for the ECS task"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "The amount of memory to reserve for the ECS task"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "The desired number of ECS tasks to run"
  type        = number
  default     = 0
}

variable "container_port" {
  description = "The port the container listens on"
  type        = number
  default     = 3000
}

variable "log_retention_in_days" {
  description = "The number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logs to S3"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

# Common Variables
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "tsaeki"
}