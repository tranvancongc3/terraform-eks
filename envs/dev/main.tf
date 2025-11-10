terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
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