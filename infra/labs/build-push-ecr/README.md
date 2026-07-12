# Build & Push Docker Image to Amazon ECR

This lab validates a fully isolated workflow for creating an Amazon ECR repository, building a Docker image, pushing it to ECR, and verifying that the image tag exists.

## Lab purpose

The lab performs the following steps:

1. Creates an Amazon ECR repository with Terraform.
2. Builds the application Docker image.
3. Authenticates Docker to Amazon ECR.
4. Tags the local image with the ECR repository URL.
5. Pushes the image to ECR.
6. Verifies that the requested image tag exists.
7. Destroys the infrastructure cleanly.

This lab does not create an ECS cluster or ECS service and does not depend on any other lab.

## Project structure

```text
ecs_lab/
├── app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
└── infra/
    ├── labs/
    │   └── build-push-ecr/
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── terraform.tfvars
    │       └── variables.tf
    └── modules/
        └── ecr/
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```

## Prerequisites

The following tools must be installed and configured:

```bash
terraform version
aws --version
docker --version
```

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

Verify that Docker is running:

```bash
docker info
```

## Terraform module

### `infra/modules/ecr/main.tf`

```hcl
resource "aws_ecr_repository" "this" {
  name         = var.repository_name
  force_delete = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}
```

### `infra/modules/ecr/variables.tf`

```hcl
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "force_delete" {
  description = "Allow deletion of a non-empty ECR repository"
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Scan images automatically when pushed"
  type        = bool
  default     = true
}
```

### `infra/modules/ecr/outputs.tf`

```hcl
output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}
```

## Lab configuration

### `infra/labs/build-push-ecr/main.tf`

```hcl
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
```

### `infra/labs/build-push-ecr/variables.tf`

```hcl
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
  description = "Allow Terraform to delete a repository containing images"
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Enable image scanning when an image is pushed"
  type        = bool
  default     = true
}
```

### `infra/labs/build-push-ecr/outputs.tf`

```hcl
output "ecr_repository_url" {
  description = "Full URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}
```

### `infra/labs/build-push-ecr/terraform.tfvars`

```hcl
aws_region      = "us-east-1"
project_name    = "ecs-lab"
repository_name = "ecs-lab-build-push"

force_delete = true
scan_on_push = true
```

## Manual execution

Run all commands from the project root unless stated otherwise.

### 1. Format and initialize Terraform

```bash
terraform -chdir=infra/labs/build-push-ecr fmt
terraform -chdir=infra/labs/build-push-ecr init
```

### 2. Validate the Terraform configuration

```bash
terraform -chdir=infra/labs/build-push-ecr validate
```

Expected result:

```text
Success! The configuration is valid.
```

### 3. Review the execution plan

```bash
terraform -chdir=infra/labs/build-push-ecr plan
```

Expected Terraform summary:

```text
Plan: 1 to add, 0 to change, 0 to destroy
```

### 4. Create the ECR repository

```bash
terraform -chdir=infra/labs/build-push-ecr apply
```

Confirm with:

```text
yes
```

### 5. Review Terraform outputs

```bash
terraform -chdir=infra/labs/build-push-ecr output
```

Retrieve the repository URL:

```bash
ECR_URL=$(terraform -chdir=infra/labs/build-push-ecr output -raw ecr_repository_url)
echo "$ECR_URL"
```

Retrieve the repository name:

```bash
ECR_REPOSITORY=$(terraform -chdir=infra/labs/build-push-ecr output -raw ecr_repository_name)
echo "$ECR_REPOSITORY"
```

### 6. Build the Docker image

```bash
docker build -t ecs-lab-app:v1 ./app
```

Verify the image:

```bash
docker image inspect ecs-lab-app:v1
```

### 7. Authenticate Docker to ECR

Extract the registry hostname:

```bash
ECR_REGISTRY=${ECR_URL%%/*}
echo "$ECR_REGISTRY"
```

Log in:

```bash
aws ecr get-login-password   --region us-east-1 |
docker login   --username AWS   --password-stdin "$ECR_REGISTRY"
```

Expected result:

```text
Login Succeeded
```

### 8. Tag the image

```bash
docker tag ecs-lab-app:v1 "$ECR_URL:v1"
```

Verify the local tag:

```bash
docker images | grep ecs-lab
```

### 9. Push the image

```bash
docker push "$ECR_URL:v1"
```

### 10. Verify the image in ECR

Verify the exact tag:

```bash
aws ecr describe-images   --repository-name "$ECR_REPOSITORY"   --image-ids imageTag=v1   --region us-east-1
```

List all image tags:

```bash
aws ecr describe-images   --repository-name "$ECR_REPOSITORY"   --region us-east-1   --query 'imageDetails[].imageTags'   --output table
```

Expected result:

```text
v1
```

## Destroy test

The repository uses `force_delete = true`, so Terraform can delete it even when images exist.

Destroy the lab:

```bash
terraform -chdir=infra/labs/build-push-ecr destroy
```

Confirm with:

```text
yes
```

Verify that the repository no longer exists:

```bash
aws ecr describe-repositories   --repository-names ecs-lab-build-push   --region us-east-1
```

AWS should return a `RepositoryNotFoundException`.

## Reproducibility test

To prove that the lab is reproducible, repeat the complete process:

```bash
terraform -chdir=infra/labs/build-push-ecr apply -auto-approve

ECR_URL=$(terraform -chdir=infra/labs/build-push-ecr output -raw ecr_repository_url)
ECR_REPOSITORY=$(terraform -chdir=infra/labs/build-push-ecr output -raw ecr_repository_name)
ECR_REGISTRY=${ECR_URL%%/*}

aws ecr get-login-password   --region us-east-1 |
docker login   --username AWS   --password-stdin "$ECR_REGISTRY"

docker build -t ecs-lab-app:v1 ./app
docker tag ecs-lab-app:v1 "$ECR_URL:v1"
docker push "$ECR_URL:v1"

aws ecr describe-images   --repository-name "$ECR_REPOSITORY"   --image-ids imageTag=v1   --region us-east-1

terraform -chdir=infra/labs/build-push-ecr destroy -auto-approve
```

## Definition of Done

The lab is complete when all of the following succeed:

- `terraform fmt`
- `terraform init`
- `terraform validate`
- `terraform plan`
- `terraform apply`
- `docker build`
- `docker login`
- `docker push`
- `aws ecr describe-images`
- `terraform destroy`

The final result must prove that:

- The ECR repository can be created independently.
- The application image can be built locally.
- The image can be pushed with a selected tag.
- AWS can return the pushed image tag.
- The repository can be destroyed cleanly.
- The full workflow can be recreated from scratch.

## Troubleshooting

### Docker daemon is not running

```bash
docker info
```

Start Docker Desktop or the Docker service before continuing.

### AWS credentials are invalid or expired

```bash
aws sts get-caller-identity
```

Refresh the AWS profile or temporary credentials.

### ECR login fails

Confirm that the configured AWS region matches the repository region:

```bash
aws configure get region
```

Then repeat the login command.

### Repository output is unavailable

Confirm that Terraform has already created the repository:

```bash
terraform -chdir=infra/labs/build-push-ecr state list
```

Expected resource:

```text
module.ecr.aws_ecr_repository.this
```

### Push is denied

Confirm that the Docker image is tagged with the complete ECR URL:

```bash
docker images
```

The repository and tag should appear in this format:

```text
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ecs-lab-build-push:v1
```

### Destroy fails because the repository contains images

Confirm that the module has:

```hcl
force_delete = true
```

Then run:

```bash
terraform -chdir=infra/labs/build-push-ecr apply -auto-approve
terraform -chdir=infra/labs/build-push-ecr destroy -auto-approve
```
