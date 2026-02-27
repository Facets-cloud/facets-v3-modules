locals {
  output_attributes = {
    controller_namespace       = local.controller_namespace
    controller_service_account = local.controller_service_account
    controller_version         = var.instance.spec.controller_version
    controller_role_arn        = aws_iam_role.alb_controller.arn
    helm_release_id            = helm_release.alb_controller.id
    secrets                    = []
  }

  output_interfaces = {}
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
