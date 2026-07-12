aws_region   = "us-east-1"
project_name = "ecs-lab"

repository_name = "ecs-lab-blue-green"
cluster_name    = "ecs-lab-blue-green-cluster"
service_name    = "ecs-lab-blue-green-service"
container_name  = "ecs-lab-app"

alb_name        = "ecs-lab-bg-alb"
codedeploy_name = "ecs-lab-blue-green"

image_tag      = "v1"
container_port = 3000