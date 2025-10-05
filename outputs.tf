# # ECS Outputs
# output "ecs_cluster_name" {
#   description = "The name of the ECS cluster"
#   value       = aws_ecs_cluster.main.name
# }

# output "ecs_cluster_arn" {
#   description = "The ARN of the ECS cluster"
#   value       = aws_ecs_cluster.main.arn
# }

# output "ecs_service_name" {
#   description = "The name of the ECS service"
#   value       = aws_ecs_service.main.name
# }

# output "ecs_task_definition_arn" {
#   description = "The ARN of the ECS task definition"
#   value       = aws_ecs_task_definition.app.arn
# }

# output "load_balancer_dns_name" {
#   description = "The DNS name of the load balancer"
#   value       = aws_lb.main.dns_name
# }

# output "load_balancer_zone_id" {
#   description = "The zone ID of the load balancer"
#   value       = aws_lb.main.zone_id
# }

# output "target_group_arn" {
#   description = "The ARN of the target group"
#   value       = aws_lb_target_group.app.arn
# }

# output "ecs_security_group_id" {
#   description = "The ID of the ECS security group"
#   value       = aws_security_group.ecs_tasks.id
# }

# output "alb_security_group_id" {
#   description = "The ID of the ALB security group"
#   value       = aws_security_group.alb.id
# }

# # Logging Outputs
# output "ecs_cloudwatch_log_group" {
#   description = "The name of the ECS CloudWatch log group"
#   value       = aws_cloudwatch_log_group.ecs.name
# }

# output "alb_cloudwatch_log_group" {
#   description = "The name of the ALB CloudWatch log group"
#   value       = aws_cloudwatch_log_group.alb.name
# }

# output "ecs_cluster_log_group" {
#   description = "The name of the ECS cluster CloudWatch log group"
#   value       = aws_cloudwatch_log_group.ecs_cluster.name
# }

# output "alb_access_logs_bucket" {
#   description = "The S3 bucket name for ALB access logs"
#   value       = aws_s3_bucket.alb_logs.bucket
# }

# output "alb_access_logs_bucket_arn" {
#   description = "The S3 bucket ARN for ALB access logs"
#   value       = aws_s3_bucket.alb_logs.arn
# }