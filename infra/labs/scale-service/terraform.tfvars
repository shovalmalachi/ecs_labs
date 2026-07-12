aws_region   = "us-east-1"
project_name = "ecs-lab"

repository_name = "ecs-lab-scale-service"
cluster_name    = "ecs-lab-scale-service-cluster"
service_name    = "ecs-lab-scale-service"
container_name  = "ecs-lab-scale-service"

image_tag            = "v1"
container_port       = 3000
initial_desired_count = 1

cpu    = 256
memory = 512