#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/terraform.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/ecr.sh"
source "$SCRIPT_DIR/lib/ecs.sh"

LAB_DIR="$ROOT_DIR/infra/labs/scale-service"

IMAGE_NAME="ecs-lab-scale-service"
IMAGE_TAG="${1:-v1}"

require_command terraform
require_command aws
require_command docker

log "Initializing Terraform"
terraform_init "$LAB_DIR"

log "Validating Terraform"
terraform_validate "$LAB_DIR"

log "Creating ECR repository"
terraform -chdir="$LAB_DIR" apply \
  -target=module.ecr \
  -auto-approve

ECR_URL="$(terraform_output "$LAB_DIR" ecr_repository_url)"
ECR_REPOSITORY="$(terraform_output "$LAB_DIR" ecr_repository_name)"
ECR_REGISTRY="${ECR_URL%%/*}"

log "Building Docker image"
docker_build "$IMAGE_NAME" "$IMAGE_TAG"

log "Logging in to ECR"
ecr_login "$ECR_REGISTRY"

log "Tagging Docker image"
docker_tag "$IMAGE_NAME" "$IMAGE_TAG" "$ECR_URL"

log "Pushing Docker image"
docker_push "$ECR_URL" "$IMAGE_TAG"

log "Verifying image exists"
aws ecr describe-images \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids "imageTag=$IMAGE_TAG" \
  --region "$AWS_REGION" \
  >/dev/null

log "Creating scale-service infrastructure"
terraform -chdir="$LAB_DIR" apply \
  -var="image_tag=$IMAGE_TAG" \
  -auto-approve

CLUSTER="$(terraform_output "$LAB_DIR" ecs_cluster_name)"
SERVICE="$(terraform_output "$LAB_DIR" ecs_service_name)"

log "Waiting for ECS service to stabilize"
ecs_wait "$CLUSTER" "$SERVICE"

log "Scale service is ready"