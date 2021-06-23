terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "accurics"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">=0.14"
}
