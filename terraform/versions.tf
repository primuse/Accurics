terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Sandbox-Infra"
    workspaces {
      name = "multi-region-ecs-fargate-demo"
    }
  }

  required_version = ">=0.14"
}
