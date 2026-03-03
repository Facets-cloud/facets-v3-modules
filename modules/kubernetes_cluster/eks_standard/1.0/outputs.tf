locals {
  # Build aws eks get-token command (works on all platforms, no binary download)
  # If role_arn is provided, add --role-arn flag for cross-account access
  aws_region = var.inputs.cloud_account.attributes.aws_region
  role_arn   = lookup(var.inputs.cloud_account.attributes, "aws_iam_role", "")

  eks_get_token_args = compact([
    "eks", "get-token",
    "--cluster-name", module.eks.cluster_name,
    "--region", local.aws_region,
    local.role_arn != "" ? "--role-arn" : "",
    local.role_arn != "" ? local.role_arn : "",
  ])

  output_attributes = {
    cluster_endpoint                  = module.eks.cluster_endpoint
    cluster_ca_certificate            = base64decode(module.eks.cluster_certificate_authority_data)
    cluster_name                      = module.eks.cluster_name
    cluster_version                   = module.eks.cluster_version
    cluster_arn                       = module.eks.cluster_arn
    cluster_id                        = module.eks.cluster_id
    oidc_issuer_url                   = module.eks.cluster_oidc_issuer_url
    oidc_provider                     = module.eks.oidc_provider
    oidc_provider_arn                 = module.eks.oidc_provider_arn
    node_iam_role_arn                 = try(module.eks.eks_managed_node_groups["system"].iam_role_arn, "")
    node_iam_role_name                = try(module.eks.eks_managed_node_groups["system"].iam_role_name, "")
    node_security_group_id            = module.eks.node_security_group_id
    cluster_iam_role_arn              = module.eks.cluster_iam_role_arn
    cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
    cluster_security_group_id         = module.eks.cluster_security_group_id
    cloud_provider                    = "aws"
    cluster_location                  = local.aws_region
    node_pool_id                      = ""
    kubernetes_provider_exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = local.eks_get_token_args
    }
    secrets = ["cluster_ca_certificate", "kubernetes_provider_exec"]
  }
  output_interfaces = {
    kubernetes = {
      host                   = module.eks.cluster_endpoint
      cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
      kubernetes_provider_exec = {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = local.eks_get_token_args
      }
      secrets = ["cluster_ca_certificate", "kubernetes_provider_exec"]
    }
  }
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
