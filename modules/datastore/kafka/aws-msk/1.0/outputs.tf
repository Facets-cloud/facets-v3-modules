locals {
  output_attributes = {
    cluster_name  = aws_msk_cluster.main.cluster_name
    kafka_version = aws_msk_cluster.main.kafka_version
    namespace     = ""
  }
  output_interfaces = {
    cluster = {
      endpoint          = aws_msk_cluster.main.bootstrap_brokers_tls != "" ? aws_msk_cluster.main.bootstrap_brokers_tls : aws_msk_cluster.main.bootstrap_brokers
      connection_string = "kafka://${aws_msk_cluster.main.bootstrap_brokers_tls != "" ? aws_msk_cluster.main.bootstrap_brokers_tls : aws_msk_cluster.main.bootstrap_brokers}"
      username          = "\"\""
      password          = "\"\""
      endpoints         = { for idx, broker in split(",", aws_msk_cluster.main.bootstrap_brokers_tls != "" ? aws_msk_cluster.main.bootstrap_brokers_tls : aws_msk_cluster.main.bootstrap_brokers) : tostring(idx) => broker }
      secrets           = ["password", "connection_string"]
    }
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}