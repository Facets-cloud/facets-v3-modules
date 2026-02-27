locals {
  output_interfaces = {}
  output_attributes = {
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}