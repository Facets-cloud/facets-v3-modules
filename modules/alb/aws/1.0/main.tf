locals {
  spec = var.instance.spec

  internal     = try(local.spec.internal, false)
  idle_timeout = try(local.spec.idle_timeout, 60)

  name_prefix = "${var.instance_name}-${var.environment.name}"
  vpc_id      = var.inputs.network_details.attributes.vpc_id
  public_ids  = var.inputs.network_details.attributes.public_subnet_ids

  # DNS / HTTPS gating
  dns_enabled = var.inputs.dns_zone != null
  zone_id     = local.dns_enabled ? var.inputs.dns_zone.attributes.zone_id : ""
  domain      = local.dns_enabled ? var.inputs.dns_zone.attributes.domain_name : ""
  prefix      = try(local.spec.subdomain_prefix, var.environment.name)
  fqdn        = local.dns_enabled ? "${local.prefix}.${local.domain}" : ""

  tags = merge(var.environment.cloud_tags, {
    Name          = var.instance_name
    environment   = var.environment.name
    resource_type = var.instance.kind
  })
}

# --- Security Group ---

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  vpc_id      = local.vpc_id
  tags        = local.tags

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "https_ingress" {
  count             = local.dns_enabled ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# --- Application Load Balancer ---

resource "aws_lb" "main" {
  name               = local.name_prefix
  internal           = local.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_ids
  idle_timeout       = local.idle_timeout
  tags               = local.tags
}

# --- HTTP Listener ---
# When dns_enabled: redirect HTTP → HTTPS
# When NOT dns_enabled: fixed-response 404 (current behavior)

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.dns_enabled ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.dns_enabled ? [] : [1]
    content {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }
}

# --- ACM Certificate (conditional) ---

resource "aws_acm_certificate" "main" {
  count             = local.dns_enabled ? 1 : 0
  domain_name       = local.fqdn
  validation_method = "DNS"
  tags              = local.tags

  lifecycle { create_before_destroy = true }
}

# --- DNS validation record ---

resource "aws_route53_record" "cert_validation" {
  count   = local.dns_enabled ? 1 : 0
  zone_id = local.zone_id
  name    = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

# --- Wait for certificate issuance ---

resource "aws_acm_certificate_validation" "main" {
  count                   = local.dns_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}

# --- HTTPS Listener (conditional) ---

resource "aws_lb_listener" "https" {
  count             = local.dns_enabled ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# --- ALB Alias DNS Record (conditional) ---

resource "aws_route53_record" "alb_alias" {
  count   = local.dns_enabled ? 1 : 0
  zone_id = local.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
