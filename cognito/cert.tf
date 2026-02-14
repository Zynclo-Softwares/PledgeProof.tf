resource "aws_acm_certificate" "cognito_cert" {
  provider          = aws.us_east_1
  domain_name       = var.cognito_custom_domain
  validation_method = "DNS"
  tags              = var.default_tags
}

resource "aws_route53_record" "cognito_cert_records" {
  for_each = {
    for dvo in aws_acm_certificate.cognito_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zynclo.zone_id
}

resource "aws_acm_certificate_validation" "cognito_cert_verified" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cognito_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cognito_cert_records : record.fqdn]
}
