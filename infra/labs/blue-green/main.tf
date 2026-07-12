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
      Ticket    = "blue-green"
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
}

module "cluster" {
  source = "../../modules/ecs-cluster"

  cluster_name = var.cluster_name
}

module "alb" {
  source = "../../modules/alb-blue-green"

  name              = var.alb_name
  vpc_id            = data.aws_vpc.default.id
  subnet_ids        = data.aws_subnets.default.ids
  container_port    = var.container_port
  health_check_path = "/"
}

module "service" {
  source = "../../modules/ecs-blue-green-service"

  service_name   = var.service_name
  container_name = var.container_name
  cluster_id     = module.cluster.cluster_id

  image     = "${module.ecr.repository_url}:${var.image_tag}"
  image_tag = var.image_tag

  aws_region              = var.aws_region
  vpc_id                  = data.aws_vpc.default.id
  subnet_ids              = data.aws_subnets.default.ids
  alb_security_group_id   = module.alb.alb_security_group_id
  blue_target_group_arn   = module.alb.blue_target_group_arn
  production_listener_arn = module.alb.production_listener_arn
  container_port          = var.container_port
}

module "codedeploy" {
  source = "../../modules/code-deploy"

  name                    = var.codedeploy_name
  cluster_name            = module.cluster.cluster_name
  service_name            = module.service.service_name
  production_listener_arn = module.alb.production_listener_arn
  blue_target_group_name  = module.alb.blue_target_group_name
  green_target_group_name = module.alb.green_target_group_name
}