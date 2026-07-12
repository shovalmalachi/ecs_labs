# Deploy an ECS Service by Image Tag

This lab validates an isolated workflow for deploying an Amazon ECS Fargate service from a specific image tag stored in Amazon ECR.

The lab is fully independent. It does not use Terraform state, outputs, repositories, clusters, or services from any other lab.

## Purpose

The lab performs the following flow:

1. Create a dedicated ECR repository.
2. Build and push application image tag `v1`.
3. Create a dedicated ECS cluster, task definition, and ECS service.
4. Wait for the service to become stable.
5. Run a smoke test against the task public IP.
6. Build and push image tag `v2`.
7. Update only `image_tag` in Terraform.
8. Verify a new task definition revision and deployment of `v2`.
9. Destroy all resources cleanly.

## Project structure

```text
ecs_lab/
├── app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
└── infra/
    ├── labs/
    │   └── deploy-by-image-tag/
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── terraform.tfvars
    │       └── variables.tf
    └── modules/
        ├── ecr/
        ├── ecs-cluster/
        └── ecs-service/
```

## Prerequisites

```bash
terraform version
aws --version
docker --version
curl --version
aws sts get-caller-identity
docker info
```

## Terraform configuration

### `infra/labs/deploy-by-image-tag/main.tf`

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
      Ticket    = "deploy-by-image-tag"
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

  cpu                   = var.cpu
  memory                = var.memory
  assign_public_ip      = true
  allowed_cidr_blocks   = ["0.0.0.0/0"]
  log_retention_in_days = 1

  environment_variables = {
    VERSION = var.image_tag
  }
}
```

### `infra/labs/deploy-by-image-tag/variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region in which the lab resources are created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "ecs-lab"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "ecs-lab-deploy-by-tag"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecs-lab-deploy-by-tag-cluster"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "ecs-lab-deploy-by-tag-service"
}

variable "container_name" {
  description = "Name of the container in the ECS task definition"
  type        = string
  default     = "ecs-lab-app"
}

variable "image_tag" {
  description = "Docker image tag deployed to ECS"
  type        = string
  default     = "v1"
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be zero or greater."
  }
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}
```

### `infra/labs/deploy-by-image-tag/outputs.tf`

```hcl
output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecs_cluster_name" {
  value = module.cluster.cluster_name
}

output "ecs_cluster_arn" {
  value = module.cluster.cluster_arn
}

output "ecs_service_name" {
  value = module.service.service_name
}

output "task_definition_arn" {
  value = module.service.task_definition_arn
}

output "log_group_name" {
  value = module.service.log_group_name
}

output "container_port" {
  value = var.container_port
}

output "deployed_image" {
  value = "${module.ecr.repository_url}:${var.image_tag}"
}
```

### `infra/labs/deploy-by-image-tag/terraform.tfvars`

```hcl
aws_region   = "us-east-1"
project_name = "ecs-lab"

repository_name = "ecs-lab-deploy-by-tag"
cluster_name    = "ecs-lab-deploy-by-tag-cluster"
service_name    = "ecs-lab-deploy-by-tag-service"
container_name  = "ecs-lab-app"

image_tag      = "v1"
container_port = 3000
desired_count  = 1

cpu    = 256
memory = 512
```

## Manual execution

Run all commands from the project root.

### 1. Format, initialize, and validate

```bash
terraform -chdir=infra/labs/deploy-by-image-tag fmt
terraform -chdir=infra/labs/deploy-by-image-tag init
terraform -chdir=infra/labs/deploy-by-image-tag validate
terraform -chdir=infra/labs/deploy-by-image-tag plan
```

Do not run a full apply yet because the ECR repository is empty.

### 2. Bootstrap the ECR repository

```bash
terraform -chdir=infra/labs/deploy-by-image-tag apply \
  -target=module.ecr \
  -auto-approve
```

### 3. Read ECR values

```bash
ECR_URL=$(terraform -chdir=infra/labs/deploy-by-image-tag output -raw ecr_repository_url)
ECR_REPOSITORY=$(terraform -chdir=infra/labs/deploy-by-image-tag output -raw ecr_repository_name)
ECR_REGISTRY=${ECR_URL%%/*}

echo "$ECR_URL"
echo "$ECR_REPOSITORY"
echo "$ECR_REGISTRY"
```

### 4. Build, authenticate, tag, and push `v1`

```bash
docker build -t ecs-lab-app:v1 ./app

aws ecr get-login-password \
  --region us-east-1 |
docker login \
  --username AWS \
  --password-stdin "$ECR_REGISTRY"

docker tag ecs-lab-app:v1 "$ECR_URL:v1"
docker push "$ECR_URL:v1"
```

Verify the image:

```bash
aws ecr describe-images \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids imageTag=v1 \
  --region us-east-1
```

### 5. Create the complete ECS infrastructure

```bash
terraform -chdir=infra/labs/deploy-by-image-tag apply \
  -auto-approve
```

Read the outputs:

```bash
CLUSTER=$(terraform -chdir=infra/labs/deploy-by-image-tag output -raw ecs_cluster_name)
SERVICE=$(terraform -chdir=infra/labs/deploy-by-image-tag output -raw ecs_service_name)
LOG_GROUP=$(terraform -chdir=infra/labs/deploy-by-image-tag output -raw log_group_name)

echo "$CLUSTER"
echo "$SERVICE"
echo "$LOG_GROUP"
```

### 6. Wait for service stability

```bash
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1
```

Verify status:

```bash
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount,Pending:pendingCount,TaskDefinition:taskDefinition}' \
  --output table
```

Expected state:

```text
Status  = ACTIVE
Desired = 1
Running = 1
Pending = 0
```

## Smoke test

Find the running task:

```bash
TASK_ARN=$(aws ecs list-tasks \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --desired-status RUNNING \
  --region us-east-1 \
  --query 'taskArns[0]' \
  --output text)
```

Find the network interface:

```bash
ENI=$(aws ecs describe-tasks \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ARN" \
  --region us-east-1 \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]" \
  --output text)
```

Find the public IP:

```bash
PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids "$ENI" \
  --region us-east-1 \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text)
```

Run the test:

```bash
curl --fail --show-error "http://${PUBLIC_IP}:3000"
```

## CloudWatch logs

```bash
aws logs tail "$LOG_GROUP" \
  --region us-east-1 \
  --since 10m
```

Follow logs:

```bash
aws logs tail "$LOG_GROUP" \
  --region us-east-1 \
  --follow
```

## Deploy image tag `v2`

Build and push a new tag:

```bash
docker build -t ecs-lab-app:v2 ./app
docker tag ecs-lab-app:v2 "$ECR_URL:v2"
docker push "$ECR_URL:v2"
```

Apply the new tag:

```bash
terraform -chdir=infra/labs/deploy-by-image-tag apply \
  -var="image_tag=v2" \
  -auto-approve
```

Wait for the deployment:

```bash
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1
```

Read the active task definition:

```bash
TASK_DEFINITION=$(aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].taskDefinition' \
  --output text)

echo "$TASK_DEFINITION"
```

Verify the deployed image:

```bash
aws ecs describe-task-definition \
  --task-definition "$TASK_DEFINITION" \
  --region us-east-1 \
  --query 'taskDefinition.containerDefinitions[0].image' \
  --output text
```

The result must end with:

```text
:v2
```

## Final evidence

```bash
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount,TaskDefinition:taskDefinition}' \
  --output table
```

```bash
aws ecs describe-task-definition \
  --task-definition "$TASK_DEFINITION" \
  --region us-east-1 \
  --query 'taskDefinition.containerDefinitions[0].image' \
  --output text
```

## Destroy

```bash
terraform -chdir=infra/labs/deploy-by-image-tag destroy \
  -var="image_tag=v2" \
  -auto-approve
```

Verify that Terraform state is empty:

```bash
terraform -chdir=infra/labs/deploy-by-image-tag state list
```

Verify that the ECR repository was removed:

```bash
aws ecr describe-repositories \
  --repository-names ecs-lab-deploy-by-tag \
  --region us-east-1
```

AWS should return a repository-not-found error.

## Definition of Done

The lab is complete when:

- Terraform formatting, initialization, validation, and planning succeed.
- The dedicated ECR repository is created.
- Image `v1` is built and pushed.
- The ECS cluster and service are created.
- The service reaches `ACTIVE` with one running task.
- The smoke test succeeds.
- CloudWatch logs are available.
- Image `v2` is built and pushed.
- Terraform creates a new task definition revision.
- ECS deploys the image ending in `:v2`.
- The updated service becomes stable.
- Terraform destroys every resource.
- The lab does not read Terraform state or outputs from another lab.

## Troubleshooting

### Task definition is blank

The shell variable was not populated or a new terminal was opened.

```bash
echo "$TASK_DEFINITION"
```

Recreate it:

```bash
TASK_DEFINITION=$(aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].taskDefinition' \
  --output text)
```

### No running task is found

```bash
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].events[0:10]' \
  --output table
```

Check stopped tasks:

```bash
aws ecs list-tasks \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --desired-status STOPPED \
  --region us-east-1
```

### ECS cannot pull the image

```bash
aws ecr describe-images \
  --repository-name "$ECR_REPOSITORY" \
  --region us-east-1 \
  --query 'imageDetails[].imageTags' \
  --output table
```

### Smoke test times out

Confirm that:

- The task received a public IP.
- The security group allows TCP port `3000`.
- The application listens on `0.0.0.0:3000`, not only `127.0.0.1:3000`.
- The task is running and producing CloudWatch logs.

### ECS service does not become stable

```bash
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].events[0:10]' \
  --output table
```

Inspect deployments:

```bash
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region us-east-1 \
  --query 'services[0].deployments' \
  --output table
```
