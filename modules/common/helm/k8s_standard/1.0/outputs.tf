locals {
  output_attributes = {
    release_name = helm_release.external_helm_charts.name
    values       = jsondecode(helm_release.external_helm_charts.metadata[0].values)
  }
  output_interfaces = {}
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
