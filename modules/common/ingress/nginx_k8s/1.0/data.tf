locals {
  # v3: Read from spec instead of CP environment variables
  tenant_base_domain    = lookup(var.instance.spec, "base_domain", "")
  tenant_base_domain_id = length(data.aws_route53_zone.base-domain-zone) > 0 ? data.aws_route53_zone.base-domain-zone[0].zone_id : ""
}

# Fetch Route53 zone by domain name
data "aws_route53_zone" "base-domain-zone" {
  count = local.tenant_provider == "aws" && local.tenant_base_domain != "" ? 1 : 0
  name  = local.tenant_base_domain
}
