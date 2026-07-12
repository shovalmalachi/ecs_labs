# New ECS Service Lab

Purpose: create a completely independent ECS Fargate service from scratch and verify that it is running and reachable.

## Resources

- One ECR repository
- One ECS cluster
- One ECS task definition
- One ECS service
- One CloudWatch log group
- One security group
- One task execution role

## Location

```text
infra/labs/new-service/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
```

## Manual workflow

Run from the project root.

### 1. Initialize and validate

```bash
terraform -chdir=infra/labs/new-service init
terraform -chdir=infra/labs/new-service validate
```

### 2. Create ECR

```bash
terraform -chdir=infra/labs/new-service apply   -target=module.ecr   -auto-approve
```

### 3. Read ECR URL

```bash
ECR_URL=$(terraform   -chdir=infra/labs/new-service   output -raw ecr_repository_url)

ECR_REGISTRY=${ECR_URL%%/*}
```

### 4. Build and push image

```bash
docker build -t ecs-lab-new-service:v1 ./app
```

```bash
aws ecr get-login-password   --region us-east-1 |
docker login   --username AWS   --password-stdin "$ECR_REGISTRY"
```

```bash
docker tag ecs-lab-new-service:v1 "$ECR_URL:v1"
docker push "$ECR_URL:v1"
```

### 5. Create the full service

```bash
terraform -chdir=infra/labs/new-service apply   -auto-approve
```

### 6. Wait and verify

```bash
CLUSTER=$(terraform   -chdir=infra/labs/new-service   output -raw ecs_cluster_name)

SERVICE=$(terraform   -chdir=infra/labs/new-service   output -raw ecs_service_name)
```

```bash
aws ecs wait services-stable   --cluster "$CLUSTER"   --services "$SERVICE"   --region us-east-1
```

```bash
aws ecs describe-services   --cluster "$CLUSTER"   --services "$SERVICE"   --region us-east-1   --query 'services[0].{
    Desired:desiredCount,
    Running:runningCount,
    Pending:pendingCount
  }'   --output table
```

Expected:

```text
Desired = 1
Running = 1
Pending = 0
```

### 7. Smoke test

```bash
TASK_ARN=$(aws ecs list-tasks   --cluster "$CLUSTER"   --service-name "$SERVICE"   --desired-status RUNNING   --region us-east-1   --query 'taskArns[0]'   --output text)

ENI=$(aws ecs describe-tasks   --cluster "$CLUSTER"   --tasks "$TASK_ARN"   --region us-east-1   --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]"   --output text)

PUBLIC_IP=$(aws ec2 describe-network-interfaces   --network-interface-ids "$ENI"   --region us-east-1   --query 'NetworkInterfaces[0].Association.PublicIp'   --output text)

curl --fail --show-error "http://${PUBLIC_IP}:3000"
```

The current application may return `"service":"devops-lab"` because the application does not yet read `SERVICE_NAME`. This is not an ECS or Terraform failure.

## Destroy

```bash
terraform -chdir=infra/labs/new-service destroy   -auto-approve
```

## Definition of Done

- ECR repository created
- Image `v1` pushed
- ECS service created
- Desired count is `1`
- Running count is `1`
- Smoke test returns HTTP success
- Destroy completes successfully

## Future automation flow

```text
init
validate
create ECR
build image
login to ECR
push image
apply infrastructure
wait for service stability
smoke test
destroy
```
