locals {
  output_interfaces = {}
  output_attributes = {
    subscription_id = local.subscription_id
    tenant_id       = local.tenant_id
    client_id       = sensitive(local.client_id)
    client_secret   = sensitive(local.client_secret)
    secrets = [
      "client_secret"
    ]
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
