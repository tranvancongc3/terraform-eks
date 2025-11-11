terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
  }
}

provider "aws" {}

# Kubernetes access for Helm via aws eks get-token
data "aws_region" "current" {}
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
  # Ensure the query only runs after the cluster is ready
  depends_on = [module.eks]
}

# Retrieve EKS access token for the Helm provider (v3 schema)
data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  project     = "prj-stock"
  environment = "dev"
  name_prefix = "${local.project}-${local.environment}"
  common_tags = {
    Project     = local.project
    Environment = local.environment
  }
}

module "vpc" {
  source               = "../../modules/vpc"
  environment          = local.environment
  name_prefix          = local.project
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  enable_nat_gateway   = false
  single_nat_gateway   = false
  enable_dns_hostnames = true
  common_tags          = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  environment        = local.environment
  name_prefix        = local.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.public_subnets
  cluster_version    = var.cluster_version
  addons_timeouts    = {
    create = "30m"
    update = "45m"
    delete = "30m"
  }

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
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa.arn
    }
    metrics-server = {
      most_recent = true
    }
  }

  # Use explicit names for EKS Security Groups
  security_group_name            = "${local.name_prefix}-cluster-sg"
  security_group_use_name_prefix = false
  node_security_group_name            = "${local.name_prefix}-node-sg"
  node_security_group_use_name_prefix = false

  node_groups = {
    on_demand = {
      name            = "${local.name_prefix}-ng-on-demand"
      use_name_prefix = false
      iam_role_use_name_prefix = false
      iam_role_name            = "eks-ng-od"
      launch_template_name            = "${local.name_prefix}-lt-on-demand"
      launch_template_use_name_prefix = false
      capacity_type  = "ON_DEMAND"
      instance_types = ["t4g.large"]
      ami_type       = "AL2023_ARM_64_STANDARD"
      launch_template_tags = {
        Name = "${local.name_prefix}-lt-on-demand"
      }
      subnet_ids     = module.vpc.public_subnets
      min_size       = 1
      desired_size   = 1
      max_size       = 3
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
      labels = {
        lifecycle = "on-demand"
        workload  = "general"
      }
      tags = local.common_tags
    }

    spot = {
      name            = "${local.name_prefix}-ng-spot"
      use_name_prefix = false
      iam_role_use_name_prefix = false
      iam_role_name            = "eks-ng-spot"
      launch_template_name            = "${local.name_prefix}-lt-spot"
      launch_template_use_name_prefix = false
      capacity_type  = "SPOT"
      instance_types = ["t4g.large"]
      ami_type       = "AL2023_ARM_64_STANDARD"
      launch_template_tags = {
        Name = "${local.name_prefix}-lt-spot"
      }
      subnet_ids     = module.vpc.public_subnets
      min_size       = 1
      desired_size   = 1
      max_size       = 4
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
      labels = {
        lifecycle = "spot"
        workload  = "general"
      }
      tags = local.common_tags
    }
  }

  access_entries = {
    cong_admin = {
      principal_arn = "arn:aws:iam::539516441248:user/cong.tv@human-brain.ai"
      policy_associations = {
        admin = {
          policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.common_tags
}

# IRSA role for Amazon EBS CSI Driver (per EKS docs recommendation)
module "ebs_csi_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  name            = "${local.name_prefix}-irsa-ebs-csi"
  use_name_prefix = false

  attach_ebs_csi_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.common_tags
}

module "aws_lb_controller" {
  source = "../../modules/aws_lb_controller"

  name_prefix       = local.name_prefix
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  vpc_id            = module.vpc.vpc_id
  region            = data.aws_region.current.id
  tags              = local.common_tags

  depends_on = [module.eks]
}

# Install Argo CD via Helm (no domain/ingress, use port-forward)
module "argocd" {
  source = "../../modules/argocd"

  namespace     = "argocd"
  release_name  = "argo-cd"
  # Optional: pass additional values if needed:
  # values = { installCRDs = true }

  depends_on = [module.eks]
}