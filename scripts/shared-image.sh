#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/terraform.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/ecr.sh"

LAB_DIR="$ROOT_DIR/infra/labs/shared-image"

IMAGE_NAME="ecs-lab-shared-image"
IMAGE_TAG="${1:-v1}"

require_command terraform
require_command aws
require_command docker
require_command jq

log "Initializing Terraform"
terraform_init "$LAB_DIR"

log "Validating Terraform"
terraform_validate "$LAB_DIR"

log "Creating shared ECR repository"
terraform -chdir="$LAB_DIR" apply \
  -target=module.ecr \
  -auto-approve

ECR_URL="$(terraform_output "$LAB_DIR" ecr_repository_url)"
ECR_REPOSITORY="$(terraform_output "$LAB_DIR" ecr_repository_name)"
ECR_REGISTRY="${ECR_URL%%/*}"

log "Building shared Docker image"
docker_build "$IMAGE_NAME" "$IMAGE_TAG"

log "Logging in to ECR"
ecr_login "$ECR_REGISTRY"

log "Tagging shared Docker image"
docker_tag "$IMAGE_NAME" "$IMAGE_TAG" "$ECR_URL"

log "Pushing shared Docker image"
docker_push "$ECR_URL" "$IMAGE_TAG"

log "Verifying shared image"
aws ecr describe-images \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids "imageTag=$IMAGE_TAG" \
  --region "$AWS_REGION" \
  >/dev/null

log "Creating shared ECS services"
terraform -chdir="$LAB_DIR" apply \
  -var="image_tag=$IMAGE_TAG" \
  -auto-approve

CLUSTER="$(terraform_output "$LAB_DIR" ecs_cluster_name)"

SERVICE_NAMES_JSON="$(
  terraform -chdir="$LAB_DIR" output -json service_names
)"

API_SERVICE="$(jq -r '.api' <<< "$SERVICE_NAMES_JSON")"
JOBS_SERVICE="$(jq -r '.jobs' <<< "$SERVICE_NAMES_JSON")"
EVENTS_SERVICE="$(jq -r '.events' <<< "$SERVICE_NAMES_JSON")"

log "Waiting for all shared services"
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services \
    "$API_SERVICE" \
    "$JOBS_SERVICE" \
    "$EVENTS_SERVICE" \
  --region "$AWS_REGION"

log "Shared services status"
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services \
    "$API_SERVICE" \
    "$JOBS_SERVICE" \
    "$EVENTS_SERVICE" \
  --region "$AWS_REGION" \
  --query 'services[].{
    Service:serviceName,
    Desired:desiredCount,
    Running:runningCount,
    Pending:pendingCount,
    TaskDefinition:taskDefinition
  }' \
  --output table

log "Shared image deployment completed successfully"