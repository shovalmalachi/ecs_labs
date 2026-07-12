#!/usr/bin/env bash
register_task_definition_with_image() {
  local current_task_definition_arn="$1"
  local new_image="$2"
  local new_version="$3"
  local output_file="$4"

  local current_task_definition
  local register_payload

  current_task_definition="$(
    aws ecs describe-task-definition \
      --task-definition "$current_task_definition_arn" \
      --region "$AWS_REGION" \
      --query 'taskDefinition' \
      --output json
  )"

  register_payload="$(
    jq \
      --arg image "$new_image" \
      --arg version "$new_version" \
      '
      del(
        .taskDefinitionArn,
        .revision,
        .status,
        .requiresAttributes,
        .compatibilities,
        .registeredAt,
        .registeredBy,
        .deregisteredAt
      )
      |
      .containerDefinitions[0].image = $image
      |
      .containerDefinitions[0].environment =
        (
          (.containerDefinitions[0].environment // [])
          | map(select(.name != "VERSION"))
          + [{name: "VERSION", value: $version}]
        )
      ' <<< "$current_task_definition"
  )"

  printf '%s\n' "$register_payload" > "$output_file"

  aws ecs register-task-definition \
    --cli-input-json "file://$output_file" \
    --region "$AWS_REGION" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text
}
create_ecs_appspec() {
  local task_definition_arn="$1"
  local container_name="$2"
  local container_port="$3"

  jq -n \
    --arg task_definition "$task_definition_arn" \
    --arg container_name "$container_name" \
    --argjson container_port "$container_port" \
    '{
      version: 0.0,
      Resources: [
        {
          TargetService: {
            Type: "AWS::ECS::Service",
            Properties: {
              TaskDefinition: $task_definition,
              LoadBalancerInfo: {
                ContainerName: $container_name,
                ContainerPort: $container_port
              },
              PlatformVersion: "LATEST"
            }
          }
        }
      ]
    }'
}

create_codedeploy_deployment() {
  local application_name="$1"
  local deployment_group_name="$2"
  local appspec_content="$3"
  local description="$4"

  local appspec_sha256
  local revision_json

  appspec_sha256="$(
    printf '%s' "$appspec_content" |
      sha256sum |
      awk '{print $1}'
  )"

  revision_json="$(
    jq -n \
      --arg content "$appspec_content" \
      --arg sha256 "$appspec_sha256" \
      '{
        revisionType: "AppSpecContent",
        appSpecContent: {
          content: $content,
          sha256: $sha256
        }
      }'
  )"

  aws deploy create-deployment \
    --application-name "$application_name" \
    --deployment-group-name "$deployment_group_name" \
    --revision "$revision_json" \
    --description "$description" \
    --region "$AWS_REGION" \
    --query 'deploymentId' \
    --output text
}

wait_for_codedeploy() {
  local deployment_id="$1"

  aws deploy wait deployment-successful \
    --deployment-id "$deployment_id" \
    --region "$AWS_REGION"
}

show_codedeploy_status() {
  local deployment_id="$1"

  aws deploy get-deployment \
    --deployment-id "$deployment_id" \
    --region "$AWS_REGION" \
    --query 'deploymentInfo.{
      DeploymentId:deploymentId,
      Status:status,
      ErrorCode:errorInformation.code,
      ErrorMessage:errorInformation.message,
      CreateTime:createTime,
      CompleteTime:completeTime
    }' \
    --output table
}