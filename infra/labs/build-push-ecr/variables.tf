variable "aws_region" {
  description = "AWS region in which the ECR repository will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "ecs-lab"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "ecs-lab-build-push"
}

variable "force_delete" {
  description = "Allow Terraform to delete the repository even when it contains images"
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Enable image scanning when an image is pushed"
  type        = bool
  default     = true
}
