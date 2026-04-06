resource "aws_security_group" "this" {
  name        = "${var.name}-redis-sg"
  description = "Allow Redis from application EC2 security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from app EC2"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-redis-sg"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.name}-redis-params"
  family = "redis7"

  parameter {
    name  = "requirepass"
    value = var.auth_token
  }

  tags = {
    Name = "${var.name}-redis-params"
  }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = replace("${var.name}-redis", "_", "-")
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.this.id]

  tags = {
    Name = "${var.name}-redis"
  }
}