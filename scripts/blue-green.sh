#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/terraform.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/ecr.sh"
source "$SCRIPT_DIR/lib/ecs.sh"
source "$SCRIPT_DIR/lib/code-deploy.sh"

LAB_DIR="$ROOT_DIR/infra/labs/blue-green"
WORK_DIR="$ROOT_DIR/.generated/blue-green"

IMAGE_NAME="ecs-lab-blue-green"
IMAGE_TAG="${1:-v2}"

require_command terraform
require_command aws
require_command docker
require_command jq
require_command curl
require_command sha256sum

mkdir -p "$WORK_DIR"

log "Checking Blue/Green infrastructure"

terraform_init "$LAB_DIR"
terraform_validate "$LAB_DIR"

if ! terraform -chdir="$LAB_DIR" state list 2>/dev/null |
  grep -q '^module\.service\.'; then
  fail "Blue/Green infrastructure is not deployed. Deploy the initial blue environment first."
fi

ECR_URL="$(terraform_output "$LAB_DIR" ecr_repository_url)"
ECR_REPOSITORY="$(terraform_output "$LAB_DIR" ecr_repository_name)"
ECR_REGISTRY="${ECR_URL%%/*}"

CLUSTER="$(terraform_output "$LAB_DIR" ecs_cluster_name)"
SERVICE="$(terraform_output "$LAB_DIR" ecs_service_name)"
CURRENT_TASK_DEFINITION="$(terraform_output "$LAB_DIR" task_definition_arn)"

APPLICATION_NAME="$(
  terraform_output "$LAB_DIR" codedeploy_application_name
)"

DEPLOYMENT_GROUP_NAME="$(
  terraform_output "$LAB_DIR" codedeploy_deployment_group_name
)"

CONTAINER_NAME="$(terraform_output "$LAB_DIR" container_name)"
CONTAINER_PORT="$(terraform_output "$LAB_DIR" container_port)"
ALB_URL="$(terraform_output "$LAB_DIR" alb_url)"

NEW_IMAGE="${ECR_URL}:${IMAGE_TAG}"
TASK_DEFINITION_FILE="$WORK_DIR/task-definition-${IMAGE_TAG}.json"
APPSPEC_FILE="$WORK_DIR/appspec-${IMAGE_TAG}.json"

log "Building image $NEW_IMAGE"

docker_build "$IMAGE_NAME" "$IMAGE_TAG"

log "Logging in to ECR"

ecr_login "$ECR_REGISTRY"

log "Tagging and pushing image"

docker_tag "$IMAGE_NAME" "$IMAGE_TAG" "$ECR_URL"
docker_push "$ECR_URL" "$IMAGE_TAG"

log "Verifying image in ECR"

aws ecr describe-images \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids "imageTag=$IMAGE_TAG" \
  --region "$AWS_REGION" \
  >/dev/null

log "Registering a new ECS task definition revision"

NEW_TASK_DEFINITION="$(
  register_task_definition_with_image \
    "$CURRENT_TASK_DEFINITION" \
    "$NEW_IMAGE" \
    "$IMAGE_TAG" \
    "$TASK_DEFINITION_FILE"
)"

[[ -n "$NEW_TASK_DEFINITION" ]] ||
  fail "Failed to register the new task definition."

log "New task definition: $NEW_TASK_DEFINITION"

APPSPEC_CONTENT="$(
  create_ecs_appspec \
    "$NEW_TASK_DEFINITION" \
    "$CONTAINER_NAME" \
    "$CONTAINER_PORT"
)"

printf '%s\n' "$APPSPEC_CONTENT" > "$APPSPEC_FILE"

log "Creating CodeDeploy deployment"

DEPLOYMENT_ID="$(
  create_codedeploy_deployment \
    "$APPLICATION_NAME" \
    "$DEPLOYMENT_GROUP_NAME" \
    "$APPSPEC_CONTENT" \
    "Deploy ${IMAGE_TAG} to ${SERVICE}"
)"

[[ -n "$DEPLOYMENT_ID" ]] ||
  fail "CodeDeploy did not return a deployment ID."

log "Deployment ID: $DEPLOYMENT_ID"
log "Waiting for Blue/Green deployment to complete"

if ! wait_for_codedeploy "$DEPLOYMENT_ID"; then
  show_codedeploy_status "$DEPLOYMENT_ID"
  fail "CodeDeploy deployment failed."
fi

show_codedeploy_status "$DEPLOYMENT_ID"

log "Waiting for ECS service stability"

log "Verifying ECS service after CodeDeploy"

SERVICE_STATUS="$(
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$AWS_REGION" \
    --query 'services[0].status' \
    --output text
)"

RUNNING_COUNT="$(
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$AWS_REGION" \
    --query 'services[0].runningCount' \
    --output text
)"

DESIRED_COUNT="$(
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$AWS_REGION" \
    --query 'services[0].desiredCount' \
    --output text
)"

[[ "$SERVICE_STATUS" == "ACTIVE" ]] ||
  fail "ECS service status is '$SERVICE_STATUS'; expected ACTIVE."

[[ "$RUNNING_COUNT" == "$DESIRED_COUNT" ]] ||
  fail "ECS running count is $RUNNING_COUNT; desired count is $DESIRED_COUNT."

log "ECS service is active: running=$RUNNING_COUNT desired=$DESIRED_COUNT"

log "Testing the production ALB"

RESPONSE="$(
  curl \
    --fail \
    --show-error \
    --silent \
    --retry 20 \
    --retry-delay 5 \
    "$ALB_URL"
)"

printf '%s\n' "$RESPONSE"

DEPLOYED_VERSION="$(
  jq -r '.version // empty' <<< "$RESPONSE"
)"

if [[ "$DEPLOYED_VERSION" != "$IMAGE_TAG" ]]; then
  fail "ALB returned version '$DEPLOYED_VERSION'; expected '$IMAGE_TAG'."
fi

log "Blue/Green deployment completed successfully"
log "Production is now serving $IMAGE_TAG"