locals {
  output_attributes = {
    node_pool_name  = "${var.instance_name}-nodepool"
    node_pool_id    = "${var.instance_name}-nodepool"
    node_class_name = "${var.instance_name}-nodeclass"
    taints = [
      for taint_key, taint_config in lookup(var.instance.spec, "taints", {}) : {
        key    = taint_key
        value  = taint_config.value
        effect = taint_config.effect
      }
    ]
    node_selector = lookup(var.instance.spec, "labels", {})
  }
  output_interfaces = {}
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}

output "attributes" {
  value = local.output_attributes
}
