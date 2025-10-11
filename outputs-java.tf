output "java_app_service_name" {
  description = "Name of the Java ECS service"
  value       = aws_ecs_service.java_app.name
}

output "java_app_log_group" {
  description = "CloudWatch log group for Java application"
  value       = aws_cloudwatch_log_group.ecs_java.name
}

output "jmx_exporter_log_group" {
  description = "CloudWatch log group for JMX Exporter sidecar"
  value       = aws_cloudwatch_log_group.ecs_java_sidecar.name
}

output "java_app_endpoint" {
  description = "Java application endpoint (ALB DNS:8080)"
  value       = "http://${aws_lb.main.dns_name}:8080"
}

output "jmx_metrics_endpoint" {
  description = "JMX metrics endpoint (ALB DNS:9090)"
  value       = "http://${aws_lb.main.dns_name}:9090/metrics"
}
