locals {
  output_attributes = {
    dashboard_count = length(local.dashboards)
    dashboard_names = local.dashboard_names
    configmap_names = local.configmap_names
    namespace       = local.grafana_namespace
  }
  output_interfaces = {}
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
