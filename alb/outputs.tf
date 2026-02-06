output "cert_arn" { 
    value = aws_acm_certificate_validation.public.certificate_arn 
}