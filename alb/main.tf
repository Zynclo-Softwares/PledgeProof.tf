# create a security group for the alb
resource "aws_security_group" "pledge_alb_sg" {
    name        = "pledge-alb-sg"
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
}

# create an alb that uses the cert from cert.tf
resource "aws_lb" "pledge_alb" {
   name = var.alb_name
   internal = false 
   load_balancer_type = "application"
   security_groups = [aws_security_group.pledge_alb_sg.id]
   subnets = data.aws_subnets.default_vpc.ids
   tags = var.default_tags
}

# create a listener for the alb that listens on 443 and uses the cert from cert.tf
resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_lb.pledge_alb.arn
    port = 443
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
    certificate_arn = aws_acm_certificate_validation.public.certificate_arn 
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "PledgeProof ALB is working!"
            status_code  = "200"
        }
    }
    tags = var.default_tags
}

