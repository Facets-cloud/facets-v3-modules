locals {
  username        = lookup(var.instance.spec, "basic_auth", false) ? "${var.instance_name}user" : ""
  password        = lookup(var.instance.spec, "basic_auth", false) && length(random_string.basic_auth_password) > 0 ? random_string.basic_auth_password[0].result : ""
  is_auth_enabled = length(local.username) > 0 && length(local.password) > 0

  output_attributes = merge(
    {
      # Always include base_domain for backward compatibility
      base_domain   = local.base_domain
      gateway_class = local.gateway_class_name
      gateway_name  = local.name
      # Load balancer DNS information
      loadbalancer_dns = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.hostname,
        data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.ip,
      null)
      loadbalancer_hostname = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.hostname, null)
      loadbalancer_ip       = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.ip, null)
    },
    # Only include base_domain_enabled if base domain is not disabled
    !lookup(var.instance.spec, "disable_base_domain", false) ? {
      base_domain_enabled = true
      } : {
      base_domain_enabled = false
    }
  )

  output_interfaces = {
    for route_key, route in local.rulesFiltered : route_key => {
      connection_string = local.is_auth_enabled ? "https://${local.username}:${local.password}@${route.host}" : "https://${route.host}"
      host              = route.host
      port              = 443
      username          = local.username
      password          = local.password
      secrets           = local.is_auth_enabled ? ["connection_string", "password"] : []
    }
  }
}

output "default" {
  value = {
    attributes = local.output_attributes
    interfaces = local.output_interfaces
  }
}
