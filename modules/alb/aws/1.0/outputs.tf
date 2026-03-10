locals {
  default_attributes = {
    alb_arn           = aws_lb.main.arn
    alb_dns_name      = aws_lb.main.dns_name
    listener_arn      = local.dns_enabled ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
    security_group_id = aws_security_group.alb.id
    fqdn              = local.fqdn
  }
}

output "default" {
  value = {
    attributes = local.default_attributes
    interfaces = {}
  }
}
