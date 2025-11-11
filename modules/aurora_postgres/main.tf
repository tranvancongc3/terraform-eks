resource "random_password" "db" {
  length              = 24
  special             = true
  override_characters = "!@#$%^&*()-_=+[]{}"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-${var.environment}-aurora-subnets"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-${var.environment}-aurora-subnets" })
}

resource "aws_security_group" "aurora" {
  name        = "${var.name_prefix}-${var.environment}-aurora-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      description = "PostgreSQL"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-${var.environment}-aurora-sg" })
}

resource "aws_security_group_rule" "allow_sg_to_aurora" {
  count                    = length(var.allowed_security_group_ids)
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
  description              = "Allow EKS nodes SG to access Aurora PostgreSQL"
}

resource "aws_rds_cluster" "this" {
  cluster_identifier        = "${var.name_prefix}-${var.environment}-aurora-pg"
  engine                    = "aurora-postgresql"
  database_name             = var.db_name
  master_username           = var.master_username
  master_password           = random_password.db.result
  vpc_security_group_ids    = [aws_security_group.aurora.id]
  db_subnet_group_name      = aws_db_subnet_group.this.name
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  apply_immediately         = var.apply_immediately
  skip_final_snapshot       = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.environment}-aurora-pg"
  })

  lifecycle {
    ignore_changes = [master_password]
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier              = "${var.name_prefix}-${var.environment}-aurora-pg-1"
  cluster_identifier      = aws_rds_cluster.this.id
  engine                  = "aurora-postgresql"
  instance_class          = var.instance_class
  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = false
  apply_immediately       = var.apply_immediately
  tags = merge(var.tags, { Role = "writer" })
}

resource "aws_rds_cluster_instance" "read" {
  count                   = var.replica_count
  identifier              = "${var.name_prefix}-${var.environment}-aurora-pg-replica-${count.index + 1}"
  cluster_identifier      = aws_rds_cluster.this.id
  engine                  = "aurora-postgresql"
  instance_class          = var.instance_class
  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = false
  apply_immediately       = var.apply_immediately
  tags = merge(var.tags, { Role = "reader" })
}

resource "aws_secretsmanager_secret" "db_master_password" {
  name        = "${var.name_prefix}-${var.environment}-aurora-master-password"
  description = "Master password for ${var.environment} Aurora PostgreSQL"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-${var.environment}-aurora-master-password" })
}

resource "aws_secretsmanager_secret_version" "db_master_password_v1" {
  secret_id     = aws_secretsmanager_secret.db_master_password.id
  secret_string = random_password.db.result
}