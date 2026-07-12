aws_region   = "us-east-1"
project_name = "ecs-lab"

repository_name = "ecs-lab-shared-image"
cluster_name    = "ecs-lab-shared-image-cluster"

image_tag      = "v1"
container_port = 3000

api_desired_count    = 1
jobs_desired_count   = 1
events_desired_count = 1

cpu    = 256
memory = 512