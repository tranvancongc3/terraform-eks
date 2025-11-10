terraform {
  backend "s3" {
    bucket         = "prj-stock-terraform-state"
    key            = "terraform-eks/dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "prj-stock-terraform-lock"
    encrypt        = true
    profile        = "stock"
  }
}