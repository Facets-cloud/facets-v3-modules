locals {
  spec = var.instance.spec
  tags = merge(var.environment.cloud_tags, {
    Name          = var.instance_name
    environment   = var.environment.name
    resource_type = var.instance.kind
  })
}

resource "aws_route53_zone" "main" {
  name = local.spec.domain_name
  tags = local.tags
}
