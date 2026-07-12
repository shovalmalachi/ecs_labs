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
      Ticket    = "new-service"
      ManagedBy = "Terraform"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.repository_name
  force_delete    = true
  scan_on_push    = true
}

module "cluster" {
  source = "../../modules/ecs-cluster"

  cluster_name       = var.cluster_name
  container_insights = false
}

module "service" {
  source = "../../modules/ecs-service"

  service_name   = var.service_name
  container_name = var.container_name
  cluster_id     = module.cluster.cluster_id

  image          = "${module.ecr.repository_url}:${var.image_tag}"
  aws_region     = var.aws_region
  vpc_id         = data.aws_vpc.default.id
  subnet_ids     = data.aws_subnets.default.ids
  container_port = var.container_port
  desired_count  = var.desired_count

  cpu              = var.cpu
  memory           = var.memory
  assign_public_ip = true

  environment_variables = {
    SERVICE_NAME = var.service_name
    VERSION      = var.image_tag
  }
}