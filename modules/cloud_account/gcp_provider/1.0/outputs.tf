locals {
  output_interfaces = {}
  output_attributes = {
    project_id  = local.project
    project     = local.project
    credentials = sensitive(local.credentials)
    region      = local.region
    secrets = [
      "credentials"
    ]
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
