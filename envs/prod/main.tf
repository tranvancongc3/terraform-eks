terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  common_tags = {
    Project     = "prj-stock"
    Environment = "prod"
  }
}

module "vpc" {
  source               = "../../modules/vpc"
  environment          = "prod"
  name_prefix          = "prj-stock"
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  common_tags          = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  environment        = "prod"
  name_prefix        = "prj-stock"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  cluster_version    = var.cluster_version

  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true
    }
    metrics-server = {
      most_recent = true
    }
  }

  node_groups = {
    on_demand = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t4g.large"]
      ami_type       = "AL2023_ARM_64_STANDARD"
      min_size       = 2
      desired_size   = 3
      max_size       = 5
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
      labels = {
        lifecycle = "on-demand"
        workload  = "general"
      }
      tags = local.common_tags
    }
  }

  tags = local.common_tags
}

# EBS CSI addon using most recent compatible version
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = data.aws_eks_addon_version.ebs_csi.version
}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}