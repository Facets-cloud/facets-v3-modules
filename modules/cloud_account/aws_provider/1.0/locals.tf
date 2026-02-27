# v3: Credentials come from spec or local CLI environment.
# No external scripts, no CP dependencies.
locals {
  spec = var.instance.spec

  role_arn    = lookup(local.spec, "role_arn", "")
  external_id = lookup(local.spec, "external_id", "")
  aws_region  = local.spec.region
}
