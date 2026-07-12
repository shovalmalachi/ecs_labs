aws_region   = "us-east-1"
project_name = "ecs-lab"

repository_name = "ecs-lab-new-service"
cluster_name    = "ecs-lab-new-service-cluster"
service_name    = "ecs-lab-new-service"
container_name  = "ecs-lab-new-service"

image_tag      = "v1"
container_port = 3000
desired_count  = 1

cpu    = 256
memory = 512