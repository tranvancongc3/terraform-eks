terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

locals {
  default_cluster_name = "${var.name_prefix}-${var.environment}-eks"
  cluster_name         = var.cluster_name != "" ? var.cluster_name : local.default_cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                 = local.cluster_name
  kubernetes_version   = var.cluster_version

  # Do not create a customer-managed KMS key; rely on AWS-managed encryption
  create_kms_key   = false
  encryption_config = null

  vpc_id      = var.vpc_id
  subnet_ids  = var.private_subnet_ids

  enable_irsa = true

  addons                   = var.addons
  addons_timeouts          = var.addons_timeouts
  eks_managed_node_groups  = var.node_groups
  access_entries           = var.access_entries

  endpoint_public_access        = true
  endpoint_private_access       = true
  endpoint_public_access_cidrs  = var.public_access_cidrs

  # Security Group naming (pass-through)
  security_group_name            = var.security_group_name
  security_group_use_name_prefix = var.security_group_use_name_prefix
  node_security_group_name            = var.node_security_group_name
  node_security_group_use_name_prefix = var.node_security_group_use_name_prefix

  tags = var.tags
}

