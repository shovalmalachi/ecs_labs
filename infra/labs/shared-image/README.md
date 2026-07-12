# Shared Image ECS Lab

This lab proves that multiple independent Amazon ECS services can use the same Docker image without sharing the same ECS service lifecycle or task definition.

## What this lab creates

- One Amazon ECR repository
- One ECS cluster
- Three independent ECS services:
  - `ecs-lab-shared-api`
  - `ecs-lab-shared-jobs`
  - `ecs-lab-shared-events`
- One task definition per service
- One CloudWatch log group per service
- One security group per service

All three services use the same ECR image and image tag.

## Important architecture rule

The services share an artifact:

```text
same ECR repository
same image tag
```

They do not share lifecycle:

```text
separate ECS services
separate task definitions
separate desired counts
separate deployments
```

## Project location

```text
infra/labs/shared-image/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
```

Reusable modules:

```text
infra/modules/
├── ecr/
├── ecs-cluster/
└── ecs-service/
```

## Manual workflow

Run all commands from the project root.

### 1. Initialize and validate

```bash
terraform -chdir=infra/labs/shared-image fmt
terraform -chdir=infra/labs/shared-image init
terraform -chdir=infra/labs/shared-image validate
terraform -chdir=infra/labs/shared-image plan
```

### 2. Create the ECR repository

```bash
terraform -chdir=infra/labs/shared-image apply   -target=module.ecr   -auto-approve
```

### 3. Read ECR values

```bash
ECR_URL=$(terraform   -chdir=infra/labs/shared-image   output -raw ecr_repository_url)

ECR_REPOSITORY=$(terraform   -chdir=infra/labs/shared-image   output -raw ecr_repository_name)

ECR_REGISTRY=${ECR_URL%%/*}
```

### 4. Build and push the shared image

```bash
docker build -t ecs-lab-shared:v1 ./app
```

```bash
aws ecr get-login-password   --region us-east-1 |
docker login   --username AWS   --password-stdin "$ECR_REGISTRY"
```

```bash
docker tag ecs-lab-shared:v1 "$ECR_URL:v1"
docker push "$ECR_URL:v1"
```

Verify:

```bash
aws ecr describe-images   --repository-name "$ECR_REPOSITORY"   --image-ids imageTag=v1   --region us-east-1
```

### 5. Create the ECS services

```bash
terraform -chdir=infra/labs/shared-image apply   -auto-approve
```

## Read service names

```bash
CLUSTER=$(terraform   -chdir=infra/labs/shared-image   output -raw ecs_cluster_name)

API_SERVICE=$(terraform   -chdir=infra/labs/shared-image   output -json service_names | jq -r '.api')

JOBS_SERVICE=$(terraform   -chdir=infra/labs/shared-image   output -json service_names | jq -r '.jobs')

EVENTS_SERVICE=$(terraform   -chdir=infra/labs/shared-image   output -json service_names | jq -r '.events')
```

## Wait for stability

```bash
aws ecs wait services-stable   --cluster "$CLUSTER"   --services     "$API_SERVICE"     "$JOBS_SERVICE"     "$EVENTS_SERVICE"   --region us-east-1
```

## Minimal validation

Check all services:

```bash
aws ecs describe-services   --cluster "$CLUSTER"   --services     "$API_SERVICE"     "$JOBS_SERVICE"     "$EVENTS_SERVICE"   --region us-east-1   --query 'services[].{
    Service:serviceName,
    Desired:desiredCount,
    Running:runningCount,
    Pending:pendingCount,
    TaskDefinition:taskDefinition
  }'   --output table
```

Expected for each service:

```text
Desired = 1
Running = 1
Pending = 0
```

Verify that each service has its own task definition but uses the same image:

```bash
for SERVICE in   "$API_SERVICE"   "$JOBS_SERVICE"   "$EVENTS_SERVICE"
do
  TASK_DEFINITION=$(aws ecs describe-services     --cluster "$CLUSTER"     --services "$SERVICE"     --region us-east-1     --query 'services[0].taskDefinition'     --output text)

  IMAGE=$(aws ecs describe-task-definition     --task-definition "$TASK_DEFINITION"     --region us-east-1     --query 'taskDefinition.containerDefinitions[0].image'     --output text)

  echo "$SERVICE -> $TASK_DEFINITION -> $IMAGE"
done
```

## Smoke test helper

```bash
smoke_test_service() {
  local service="$1"

  local task_arn
  local eni
  local public_ip

  task_arn=$(aws ecs list-tasks     --cluster "$CLUSTER"     --service-name "$service"     --desired-status RUNNING     --region us-east-1     --query 'taskArns[0]'     --output text)

  eni=$(aws ecs describe-tasks     --cluster "$CLUSTER"     --tasks "$task_arn"     --region us-east-1     --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]"     --output text)

  public_ip=$(aws ec2 describe-network-interfaces     --network-interface-ids "$eni"     --region us-east-1     --query 'NetworkInterfaces[0].Association.PublicIp'     --output text)

  echo "Testing $service at http://${public_ip}:3000"

  curl     --fail     --show-error     --silent     "http://${public_ip}:3000"

  echo
}
```

Run:

```bash
smoke_test_service "$API_SERVICE"
smoke_test_service "$JOBS_SERVICE"
smoke_test_service "$EVENTS_SERVICE"
```

## Note about the application response

The application may currently return:

```json
{
  "service": "devops-lab",
  "version": "v1",
  "spring_profile": "default"
}
```

for all three services.

This is not an ECS or Terraform failure. It means the application is likely not reading the `SERVICE_NAME` environment variable passed by each task definition.

The infrastructure is still valid if:

- all three ECS services are running;
- each service has its own task definition;
- all services use the same ECR image;
- each endpoint responds successfully.

To display a different service name from each endpoint, update the application code to read:

```text
SERVICE_NAME
```

from the container environment.

## Optional independence test

Scale only the jobs service to zero:

```bash
terraform -chdir=infra/labs/shared-image apply   -var="jobs_desired_count=0"   -auto-approve
```

Verify that API and events remain at one task:

```bash
aws ecs describe-services   --cluster "$CLUSTER"   --services     "$API_SERVICE"     "$JOBS_SERVICE"     "$EVENTS_SERVICE"   --region us-east-1   --query 'services[].{
    Service:serviceName,
    Desired:desiredCount,
    Running:runningCount
  }'   --output table
```

Restore jobs:

```bash
terraform -chdir=infra/labs/shared-image apply   -var="jobs_desired_count=1"   -auto-approve
```

## Destroy

```bash
terraform -chdir=infra/labs/shared-image destroy   -auto-approve
```

Verify that the state is empty:

```bash
terraform -chdir=infra/labs/shared-image state list
```

## Definition of Done

The lab is complete when:

- the shared ECR repository is created;
- image tag `v1` is pushed successfully;
- all three ECS services are active;
- all three services have `Running = 1`;
- each service has its own task definition;
- all task definitions use the same ECR image;
- all three smoke tests return a successful HTTP response;
- Terraform destroys the lab cleanly.

The per-service name in the HTTP response is optional application-level validation and is not required to prove infrastructure independence.
