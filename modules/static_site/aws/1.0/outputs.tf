locals {
  default_attributes = {
    bucket_name         = aws_s3_bucket.site.id
    bucket_arn          = aws_s3_bucket.site.arn
    distribution_id     = aws_cloudfront_distribution.site.id
    distribution_domain = aws_cloudfront_distribution.site.domain_name
    fqdn                = local.fqdn
  }
}

output "default" {
  value = {
    attributes = local.default_attributes
    interfaces = {}
  }
}
