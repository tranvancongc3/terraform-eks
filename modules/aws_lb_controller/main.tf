locals {
  irsa_name = "${var.name_prefix}-irsa-aws-lb-controller"
}

# Determine region if not provided by the root module
data "aws_region" "current" {}

module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = ">= 5.39.1"

  create                            = true
  name                              = local.irsa_name
  use_name_prefix                   = false
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    eks = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account_name}"]
    }
  }

  tags = var.tags
}

resource "helm_release" "aws_load_balancer_controller" {
  name             = var.service_account_name
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = var.namespace
  create_namespace = false

  # Use the provided region if set; otherwise use the data source
  values = [yamlencode({
    region        = coalesce(var.region, data.aws_region.current.id)
    vpcId         = var.vpc_id
    clusterName   = var.cluster_name
    serviceAccount = {
      create = true
      name   = var.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn" = module.lb_controller_irsa.arn
      }
    }
  })]

  depends_on = [module.lb_controller_irsa]
}