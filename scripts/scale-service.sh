#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/terraform.sh"
source "$SCRIPT_DIR/lib/ecs.sh"

LAB_DIR="$ROOT_DIR/infra/labs/scale-service"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-scale-service.sh"

DESIRED_COUNT="${1:-}"
IMAGE_TAG="${2:-v1}"

require_command terraform
require_command aws

if [[ -z "$DESIRED_COUNT" ]]; then
  fail "Usage: $0 <desired-count> [image-tag]"
fi

if ! [[ "$DESIRED_COUNT" =~ ^[0-9]+$ ]]; then
  fail "Desired count must be a non-negative integer."
fi

if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
  fail "Deployment script is missing or not executable: $DEPLOY_SCRIPT"
fi

lab_has_resources() {
  terraform -chdir="$LAB_DIR" state list 2>/dev/null |
    grep -q '^module\.service\.'
}

read_outputs() {
  CLUSTER="$(terraform_output "$LAB_DIR" ecs_cluster_name 2>/dev/null || true)"
  SERVICE="$(terraform_output "$LAB_DIR" ecs_service_name 2>/dev/null || true)"
}

service_exists_in_aws() {
  local status

  status="$(
    aws ecs describe-services \
      --cluster "$CLUSTER" \
      --services "$SERVICE" \
      --region "$AWS_REGION" \
      --query 'services[0].status' \
      --output text 2>/dev/null || true
  )"

  [[ "$status" == "ACTIVE" ]]
}

bootstrap_service() {
  log "Scale-service infrastructure is not ready; deploying it first"
  "$DEPLOY_SCRIPT" "$IMAGE_TAG"
}

# The lab may have been destroyed or never deployed.
if ! lab_has_resources; then
  bootstrap_service
fi

read_outputs

# Never send empty identifiers to AWS.
if [[ -z "$CLUSTER" || "$CLUSTER" == "null" ]]; then
  fail "Terraform output 'ecs_cluster_name' is empty after deployment."
fi

if [[ -z "$SERVICE" || "$SERVICE" == "null" ]]; then
  fail "Terraform output 'ecs_service_name' is empty after deployment."
fi

# Handles partial state, manual deletion, or stale Terraform state.
if ! service_exists_in_aws; then
  log "ECS service is missing or inactive; reconciling the lab"
  "$DEPLOY_SCRIPT" "$IMAGE_TAG"

  read_outputs

  [[ -n "$CLUSTER" && "$CLUSTER" != "null" ]] ||
    fail "Cluster output is still empty after reconciliation."

  [[ -n "$SERVICE" && "$SERVICE" != "null" ]] ||
    fail "Service output is still empty after reconciliation."

  service_exists_in_aws ||
    fail "ECS service '$SERVICE' is not ACTIVE after reconciliation."
fi

log "Scaling service '$SERVICE' in cluster '$CLUSTER' to $DESIRED_COUNT tasks"

ecs_scale \
  "$CLUSTER" \
  "$SERVICE" \
  "$DESIRED_COUNT" \
  >/dev/null

log "Waiting for ECS service to stabilize"

ecs_wait \
  "$CLUSTER" \
  "$SERVICE"

STATUS_JSON="$(
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$AWS_REGION" \
    --query 'services[0].{
      Service:serviceName,
      Desired:desiredCount,
      Running:runningCount,
      Pending:pendingCount
    }' \
    --output json
)"

CURRENT_DESIRED="$(
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$AWS_REGION" \
    --query 'services[0].desiredCount' \
    --output text
)"

CURRENT_RUNNING="$(
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$AWS_REGION" \
    --query 'services[0].runningCount' \
    --output text
)"

printf '%s\n' "$STATUS_JSON"

if [[ "$CURRENT_DESIRED" != "$DESIRED_COUNT" ]]; then
  fail "Desired count is $CURRENT_DESIRED; expected $DESIRED_COUNT."
fi

if [[ "$CURRENT_RUNNING" != "$DESIRED_COUNT" ]]; then
  fail "Running count is $CURRENT_RUNNING; expected $DESIRED_COUNT."
fi

log "Scale completed successfully"