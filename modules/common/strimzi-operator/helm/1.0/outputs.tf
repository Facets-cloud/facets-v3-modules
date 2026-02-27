locals {
  output_attributes = {
    namespace     = local.namespace
    release_name  = helm_release.strimzi_operator.name
    release_id    = helm_release.strimzi_operator.id
    chart_version = helm_release.strimzi_operator.version
    revision      = helm_release.strimzi_operator.metadata[0].revision
    operator_name = "strimzi-cluster-operator"
    repository    = local.repository
    chart_name    = local.chart_name
    status        = helm_release.strimzi_operator.status
  }
  output_interfaces = {}
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}