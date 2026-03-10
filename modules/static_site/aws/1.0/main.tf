locals {
  spec = var.instance.spec

  index_document = try(local.spec.index_document, "index.html")
  error_document = try(local.spec.error_document, "index.html")
  price_class    = try(local.spec.price_class, "PriceClass_100")
  force_destroy  = try(local.spec.force_destroy, true)

  name_prefix = "${var.instance_name}-${var.environment.name}"
  bucket_name = "${var.environment.unique_name}-${var.instance_name}"

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

# --- S3 Bucket (private) ---

resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = local.force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- CloudFront Origin Access Control ---

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = local.name_prefix
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- S3 Bucket Policy (allow CloudFront OAC) ---

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })
}

# --- ACM Certificate (conditional) ---

resource "aws_acm_certificate" "site" {
  count             = local.dns_enabled ? 1 : 0
  domain_name       = local.fqdn
  validation_method = "DNS"
  tags              = local.tags

  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "cert_validation" {
  count   = local.dns_enabled ? 1 : 0
  zone_id = local.zone_id
  name    = tolist(aws_acm_certificate.site[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.site[0].domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.site[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "site" {
  count                   = local.dns_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}

# --- CloudFront Distribution ---

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = local.index_document
  price_class         = local.price_class
  aliases             = local.dns_enabled ? [local.fqdn] : []
  tags                = local.tags

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # SPA support: serve index.html for 403 (S3 returns 403 for missing keys with OAC)
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/${local.error_document}"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/${local.error_document}"
  }

  # TLS — use ACM cert when dns_zone provided, otherwise CloudFront default cert
  dynamic "viewer_certificate" {
    for_each = local.dns_enabled ? [1] : []
    content {
      acm_certificate_arn      = aws_acm_certificate_validation.site[0].certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.dns_enabled ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# --- Route53 Alias Record (conditional) ---

resource "aws_route53_record" "site_alias" {
  count   = local.dns_enabled ? 1 : 0
  zone_id = local.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
