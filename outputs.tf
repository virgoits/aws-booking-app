output "alb_dns_name" {
  description = "Public URL of the load balancer"
  value       = aws_lb.app.dns_name
}
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
}