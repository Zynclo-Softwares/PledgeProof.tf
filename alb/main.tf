# create a security group for the alb
resource "aws_security_group" "alb_sg" {
    name        = "${var.alb_name}-sg"
    description = "Security group for PledgeProof ALB"
    vpc_id      = data.aws_vpc.default.id
    
    # allow inbound HTTP and HTTPS
    ingress {
        description = "Allow HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "Allow HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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
    lifecycle {
      create_before_destroy = true
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

# ---------------------------------------------------------------------------
# The api.pledgeproof.zynclo.com A-alias that used to point here was replaced
# out-of-band during the Railway DNS cutover: it is now a CNAME -> Railway,
# managed outside this module. Terraform must therefore STOP managing this
# record — otherwise every apply tries to recreate the A record and Route 53
# rejects it ("conflicting RRSet of type CNAME with the same DNS name").
#
# `destroy = false` drops the resource from state WITHOUT a Route 53 delete
# call (the old A record is already gone, and a delete would both error and
# risk the live CNAME). Delete this block after it has applied once.
# ---------------------------------------------------------------------------
removed {
  from = aws_route53_record.alb_alias
  lifecycle {
    destroy = false
  }
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
