terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "tfstate-<ACCOUNT_ID>"
    key          = "containerized-lambda/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  # Applied to every taggable resource in this config (ECR repo, IAM role, Lambda, ...).
  default_tags {
    tags = {
      Project = "containerized-lambda-project"
    }
  }
}
