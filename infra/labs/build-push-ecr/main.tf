terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Ticket    = "build-push-ecr"
      ManagedBy = "Terraform"
    }
  }
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.repository_name
  force_delete    = var.force_delete
  scan_on_push    = var.scan_on_push
}
