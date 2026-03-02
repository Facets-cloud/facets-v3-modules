# v3: Credentials come from spec or local CLI environment (az login).
# No external scripts, no CP dependencies.
locals {
  spec = var.instance.spec

  subscription_id = local.spec.subscription_id
  tenant_id       = lookup(local.spec, "tenant_id", "")
  client_id       = lookup(local.spec, "client_id", "")
  client_secret   = lookup(local.spec, "client_secret", "")
}
