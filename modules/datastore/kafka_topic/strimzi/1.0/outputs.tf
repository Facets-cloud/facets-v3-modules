locals {
  output_attributes = {
    cluster_name = local.cluster_name
    namespace    = local.namespace
  }

  output_interfaces = {
    topics = {
      for key, topic in local.spec : key => {
        topic_name         = key
        partitions         = topic.partitions
        replication_factor = topic.replication_factor
      }
    }
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
