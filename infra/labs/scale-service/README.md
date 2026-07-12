# Scale Service Lab

Purpose: demonstrate manual scaling of an Amazon ECS service using the AWS CLI.

## Resources

- One ECR repository
- One ECS cluster
- One ECS service
- One task definition

## Manual workflow

### 1. Initialize

```bash
terraform -chdir=infra/labs/scale-service init
terraform -chdir=infra/labs/scale-service validate
```

### 2. Create ECR

```bash
terraform -chdir=infra/labs/scale-service apply   -target=module.ecr   -auto-approve
```

### 3. Build and push image

```bash
docker build -t ecs-lab-scale-service:v1 ./app

ECR_URL=$(terraform -chdir=infra/labs/scale-service output -raw ecr_repository_url)
ECR_REGISTRY=${ECR_URL%%/*}

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker tag ecs-lab-scale-service:v1 "$ECR_URL:v1"
docker push "$ECR_URL:v1"
```

### 4. Create infrastructure

```bash
terraform -chdir=infra/labs/scale-service apply -auto-approve
```

### 5. Read outputs

```bash
CLUSTER=$(terraform -chdir=infra/labs/scale-service output -raw ecs_cluster_name)
SERVICE=$(terraform -chdir=infra/labs/scale-service output -raw ecs_service_name)
```

### 6. Scale to 3

```bash
aws ecs update-service   --cluster "$CLUSTER"   --service "$SERVICE"   --desired-count 3   --region us-east-1

aws ecs wait services-stable   --cluster "$CLUSTER"   --services "$SERVICE"   --region us-east-1
```

Verify:

```bash
aws ecs describe-services   --cluster "$CLUSTER"   --services "$SERVICE"   --region us-east-1   --query 'services[0].{Desired:desiredCount,Running:runningCount}'   --output table
```

### 7. Scale back to 1

```bash
aws ecs update-service   --cluster "$CLUSTER"   --service "$SERVICE"   --desired-count 1   --region us-east-1

aws ecs wait services-stable   --cluster "$CLUSTER"   --services "$SERVICE"   --region us-east-1
```

### 8. Destroy

```bash
terraform -chdir=infra/labs/scale-service destroy -auto-approve
```

## Definition of Done

- Image pushed successfully
- ECS service created
- Scale 1 → 3 succeeds
- Scale 3 → 1 succeeds
- Running count matches Desired count
- Destroy completes successfully

## Future script flow

```text
init
validate
create ECR
build
push
apply
scale (CLI)
wait
verify
destroy
```
