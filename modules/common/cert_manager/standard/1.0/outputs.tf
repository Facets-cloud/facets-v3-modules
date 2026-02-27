locals {
  output_attributes = {
    cluster_issuer_http = "letsencrypt-prod-http01"
    cluster_issuer_dns  = ""
    use_gts             = false
    namespace           = local.cert_mgr_namespace
    acme_email          = local.acme_email
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
