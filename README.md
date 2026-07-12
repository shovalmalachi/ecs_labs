# ECS Operations Lab

A modular AWS ECS lab demonstrating common ECS operational workflows using **Terraform**, **Docker**, **Bash**, **AWS CLI**, and **AWS CodeDeploy**.

The project is designed around independent infrastructure labs, reusable Terraform modules, and workflow automation scripts.

---

# Architecture

```text
ecs_lab/
├── app/                    
│
├── infra/
│   ├── modules/           
│   └── labs/               
│
├── scripts/
│   ├── lib/                
│   └── *.sh               
│
├── Makefile
└── README.md
```

## Design Principles

- Reusable Terraform modules
- Independent Terraform root modules
- Shared Bash libraries
- One workflow script per operation
- Makefile as the project entry point

Each lab is completely isolated and can be deployed or destroyed independently.

---

# Implemented ECS Operations

| Operation | Description |
|-----------|-------------|
| **Build & Push** | Build a Docker image and push it to Amazon ECR |
| **Deploy by Image Tag** | Deploy an ECS service using a specific image tag |
| **Shared Image** | Deploy multiple ECS services from the same Docker image |
| **New Service** | Provision a brand-new ECS service |
| **Manual Scaling** | Scale an ECS service using the AWS CLI |
| **Blue / Green Deployment** | Perform zero-downtime deployments using AWS CodeDeploy |

---

# Usage

> **Note**
>
> Every deployment workflow accepts a **TAG** parameter, allowing deployment of a specific Docker image version.

## Deploy

```bash
make build-push TAG=v1

make deploy-image TAG=v1

make shared-image TAG=v1

make new-service TAG=v1

make scale COUNT=3 TAG=v1

make blue-green-infra TAG=v1

make blue-green-deploy TAG=v2
```

## Cleanup

```bash
make destroy-all
```

---

# Technologies

- Terraform
- Amazon ECS (Fargate)
- Amazon ECR
- AWS CodeDeploy
- Application Load Balancer (ALB)
- Docker
- Bash
- AWS CLI
- Make

---

# Validation

Validate all Terraform labs:

```bash
for lab in infra/labs/*; do
    terraform -chdir="$lab" validate
done
```

Validate Bash scripts:

```bash
find scripts -name "*.sh" -exec bash -n {} \;
```

Format Terraform:

```bash
terraform fmt -recursive
```

---

# Security

The repository intentionally **does not contain**:

- AWS credentials
- AWS access keys
- Secrets
- Passwords
- Private keys

The committed `terraform.tfvars` files contain **non-sensitive lab configuration only** (resource names, regions, image tags, CPU, memory, etc.).

**Never store credentials, passwords, tokens, private keys, or any other sensitive information in `terraform.tfvars` or any other file committed to this repository.**

Terraform state files (`*.tfstate`), provider directories (`.terraform/`), and generated deployment artifacts are excluded from Git.
---

# Project Highlights

- Modular Terraform architecture
- Independent infrastructure labs
- Reusable infrastructure modules
- Bash automation library
- ECS deployment automation
- Manual operational workflows
- Blue/Green deployments with AWS CodeDeploy
- Repeatable infrastructure cleanup