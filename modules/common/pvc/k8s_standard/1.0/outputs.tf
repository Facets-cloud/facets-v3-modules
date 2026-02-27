locals {
  output_attributes = {
    pvc_name = local.name
  }
  output_interfaces = {}
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
