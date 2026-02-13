# create a security group for the alb
resource "aws_security_group" "alb_sg" {
    name        = "${var.alb_name}-sg"
    description = "Security group for PledgeProof ALB"
    vpc_id      = data.aws_vpc.default.id
    
    # allow inbound HTTP and HTTPS from my ip only for now
    ingress {
        description = "Allow HTTP from my IP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }
    ingress {
        description = "Allow HTTPS from my IP"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }
    # allow all outbound (or restrict as needed)
    egress {
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = var.default_tags
    # after deployment there should be no drift trigger for ip change since i will use cli to update the ip often
    lifecycle {
      ignore_changes = [ingress]
    }
}

# create an alb that uses the cert from cert.tf
resource "aws_lb" "alb" {
   name = var.alb_name
   internal = false 
   load_balancer_type = "application"
   security_groups = [aws_security_group.alb_sg.id]
   subnets = data.aws_subnets.default_vpc.ids
   tags = var.default_tags
}

# create a listener for the alb that listens on 443 and uses the cert from cert.tf
resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_lb.alb.arn
    port = 443
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
    certificate_arn = aws_acm_certificate_validation.verified_certificate.certificate_arn 
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.alb_tg.arn  # ✅ Links ALB→TG
    }
    tags = var.default_tags
}

# if http then redirect to https
resource "aws_lb_listener" "http_listener" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "redirect"
        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
    tags = var.default_tags
}

# create an alias record in route53 for the alb
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.zynclo.zone_id
  name    = var.alb_domain_name
  type    = "A"
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [aws_lb.alb]
}

# create an alb target group (for using with a fargate ecs service later)
resource "aws_lb_target_group" "alb_tg" {
    name     = "${var.alb_name}-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.default.id
    target_type = "ip"                           
    health_check {                               
      enabled             = true
      healthy_threshold   = 2
      interval            = 30
      path                = "/health"             
      matcher             = "200"
      unhealthy_threshold = 2
      timeout             = 5
    }
    tags = var.default_tags
}
