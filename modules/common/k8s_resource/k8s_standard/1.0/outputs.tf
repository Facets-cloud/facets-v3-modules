locals {
  output_interfaces = {}
  output_attributes = {
    resource_name      = local.name
    resource_namespace = local.namespace
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
