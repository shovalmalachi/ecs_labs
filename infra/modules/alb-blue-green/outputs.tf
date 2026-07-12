output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  value = aws_lb_target_group.blue.name
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  value = aws_lb_target_group.green.name
}

output "production_listener_arn" {
  value = aws_lb_listener.production.arn
}
