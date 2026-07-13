terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # bucket and region are supplied at init time:
    # terraform -chdir=infra init -backend-config="bucket=${TERRAFORM_TFSTATE_S3_BUCKET}" -backend-config="region=${TERRAFORM_TFSTATE_S3_REGION}" -input=false
    key          = "containerized-lambda/terraform.tfstate"
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
