terraform {
  backend "s3" {
    bucket         = "pic-kabu-terraform-state"
    key            = "terraform-eks/prod/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "pic-kabu-terraform-lock"
    encrypt        = true
    profile        = "stock"
  }
}