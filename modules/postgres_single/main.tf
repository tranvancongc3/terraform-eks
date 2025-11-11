resource "random_password" "db" {
  length              = 24
  special             = false
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-rds-subnets"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-rds-subnets" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for single-instance RDS PostgreSQL"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_sg_to_rds" {
  count                    = length(var.allowed_security_group_ids)
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
  description              = "Allow EKS nodes SG to access PostgreSQL"
}

resource "aws_secretsmanager_secret" "db_master_password" {
  name        = "${var.name_prefix}-postgres-credentials"
  description = "PostgreSQL credentials (username/password)"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-postgres-credentials" })
}

resource "aws_secretsmanager_secret_version" "db_master_password_v1" {
  secret_id     = aws_secretsmanager_secret.db_master_password.id
  secret_string = jsonencode({
    username = var.username,
    password = random_password.db.result
  })
}

resource "aws_db_instance" "primary" {
  identifier                = "${var.name_prefix}-postgres"
  engine                    = "postgres"
  port                      = 5432
  instance_class            = var.instance_class
  db_name                   = var.db_name
  username                  = var.username
  password                  = random_password.db.result

  allocated_storage         = var.allocated_storage
  storage_type              = var.storage_type

  vpc_security_group_ids    = [aws_security_group.rds.id]
  db_subnet_group_name      = aws_db_subnet_group.this.name
  publicly_accessible       = var.publicly_accessible
  multi_az                  = false

  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  apply_immediately         = var.apply_immediately
  skip_final_snapshot       = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
    Role = "primary"
  })

  lifecycle {
    ignore_changes = [password]
  }
}