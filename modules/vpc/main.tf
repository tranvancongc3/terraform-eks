terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  name              = "${var.name_prefix}-${var.environment}-vpc"
  eks_cluster_name  = "${var.name_prefix}-${var.environment}-eks"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 3)]

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
  }

  tags = var.common_tags
}