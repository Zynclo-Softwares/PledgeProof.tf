resource "aws_acm_certificate" "public_certificate" {
  domain_name       = var.alb_domain_name
  validation_method = "DNS"
  tags = var.default_tags
}


resource "aws_route53_record" "certificate_records" {
  for_each = {
    for dvo in aws_acm_certificate.public_certificate.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "verified_certificate" {
   certificate_arn         = aws_acm_certificate.public_certificate.arn
   validation_record_fqdns = [for record in aws_route53_record.certificate_records : record.fqdn]
}