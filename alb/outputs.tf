output "cert_arn" { 
    value = aws_acm_certificate_validation.verified_certificate.certificate_arn
}

output "alb_target_group_arn" {
    value = aws_lb_target_group.alb_tg.arn
}