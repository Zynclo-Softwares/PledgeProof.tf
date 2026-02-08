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