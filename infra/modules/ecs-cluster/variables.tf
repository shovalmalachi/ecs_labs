variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = false
}