locals {
  output_attributes = {
    name               = var.instance_name
    namespace          = local.namespace
    mtu                = local.mtu
    service_type       = local.service_type
    enable_ip_forward  = local.enable_ip_forward
    operator_namespace = local.operator_namespace
  }
  output_interfaces = {
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}