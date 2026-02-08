resource "aws_subnet" "private_1d" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.48.0/20"
  availability_zone = "ca-central-1d"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1b" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.64.0/20" 
  availability_zone = "ca-central-1b"
  map_public_ip_on_launch = false
}

locals {
  private_subnet_ids = [
    aws_subnet.private_1d.id,
    aws_subnet.private_1b.id
  ]
}

# securoty group for ecs service to allow traffic from alb
resource "aws_security_group" "ecs_service_sg" {
    name        = "${var.task_name}-service-sg"
    description = "Allow traffic from ALB to ECS service"
    vpc_id      = data.aws_vpc.default.id   
    ingress {
        description = "Allow traffic from ALB"
        from_port   = var.container_port
        to_port     = var.container_port
        protocol    = "tcp"
        security_groups = [var.alb_sg_id]  
    }
    egress {
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = var.default_tags
}