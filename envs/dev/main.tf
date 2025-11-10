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
  # Đảm bảo chỉ truy vấn khi cluster đã sẵn sàng
  depends_on = [module.eks]
}

# Lấy token truy cập EKS để dùng cho Helm provider (v3 schema)
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
  common_tags = {
    Project     = "prj-stock"
    Environment = "dev"
  }
}

module "vpc" {
  source               = "../../modules/vpc"
  environment          = "dev"
  name_prefix          = "prj-stock"
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  enable_nat_gateway   = false
  single_nat_gateway   = false
  enable_dns_hostnames = true
  common_tags          = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  environment        = "dev"
  name_prefix        = "prj-stock"
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

  node_groups = {
    on_demand = {
      name            = "prj-stock-dev-ng-on-demand"
      use_name_prefix = false
      iam_role_use_name_prefix = false
      iam_role_name            = "eks-ng-od"
      capacity_type  = "ON_DEMAND"
      instance_types = ["t4g.large"]
      ami_type       = "AL2023_ARM_64_STANDARD"
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
      name            = "prj-stock-dev-ng-spot"
      use_name_prefix = false
      iam_role_use_name_prefix = false
      iam_role_name            = "eks-ng-spot"
      capacity_type  = "SPOT"
      instance_types = ["t4g.large"]
      ami_type       = "AL2023_ARM_64_STANDARD"
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

# IRSA role cho Amazon EBS CSI Driver (theo khuyến nghị docs EKS)
module "ebs_csi_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name = "${module.eks.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.common_tags
}

# IRSA role for AWS Load Balancer Controller (using terraform-aws-iam submodule)
module "lb_controller_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name = "${module.eks.cluster_name}-aws-lb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    this = {
      provider_arn              = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.common_tags
}

# Install AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  # Đảm bảo cài đặt helm chỉ diễn ra sau khi cluster và IRSA sẵn sàng
  depends_on = [
    module.eks,
    module.lb_controller_irsa,
  ]

  # Tăng độ ổn định khi chạy lặp
  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  force_update    = true

  # Giá trị chart (sử dụng values YAML để tránh cảnh báo deprecated)
  values = [
    yamlencode({
      region     = data.aws_region.current.name
      vpcId      = module.vpc.vpc_id
      clusterName = module.eks.cluster_name
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.lb_controller_irsa.arn
        }
      }
    })
  ]
}