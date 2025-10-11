output "java_app_service_name" {
  description = "Name of the Java ECS service"
  value       = aws_ecs_service.java_app.name
}

output "java_app_log_group" {
  description = "CloudWatch log group for Java application"
  value       = aws_cloudwatch_log_group.ecs_java.name
}

output "java_app_endpoint" {
  description = "Java application endpoint (ALB DNS:8080)"
  value       = "http://${aws_lb.main.dns_name}:8080"
}

output "cloudwatch_metrics_namespace" {
  description = "CloudWatch Metrics namespace for JMX metrics"
  value       = "JavaApp/JMX"
}

output "cloudwatch_agent_log_group" {
  description = "CloudWatch log group for CloudWatch Agent sidecar"
  value       = aws_cloudwatch_log_group.ecs_cloudwatch_agent.name
}
