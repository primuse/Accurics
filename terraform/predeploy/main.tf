provider "aws" {
  region = "us-east-1"
}

module "tfstate-backend" {
  source  = "cloudposse/tfstate-backend/aws"
  version = "0.29.0"

  enabled     = true
  environment = "multi-region-ecs-fargate-demo"
  name        = "terraform"
  stage       = "dev"

  terraform_backend_config_file_path = ".."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}