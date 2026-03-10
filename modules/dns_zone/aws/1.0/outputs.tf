locals {
  default_attributes = {
    zone_id      = aws_route53_zone.main.zone_id
    domain_name  = aws_route53_zone.main.name
    name_servers = join(",", aws_route53_zone.main.name_servers)
  }
}

output "default" {
  value = {
    attributes = local.default_attributes
    interfaces = {}
  }
}
