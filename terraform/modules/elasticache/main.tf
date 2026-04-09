resource "aws_security_group" "this" {
  name        = "${var.name}-redis-sg"
  description = "Allow Redis from EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  tags = {
    Name = var.name
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "this" {
  cluster_id        = replace(var.name, "_", "-")
  engine            = "redis"
  engine_version    = var.engine_version
  node_type         = var.node_type
  num_cache_nodes   = 1
  port              = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  tags = {
    Name = var.name
  }
}
