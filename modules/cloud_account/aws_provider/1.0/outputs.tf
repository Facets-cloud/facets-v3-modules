locals {
  output_interfaces = {}
  output_attributes = {
    aws_iam_role = local.role_arn
    session_name = local.role_arn != "" ? "facets-${var.environment.unique_name}-${var.instance_name}" : ""
    external_id  = local.external_id
    aws_region   = local.aws_region
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
