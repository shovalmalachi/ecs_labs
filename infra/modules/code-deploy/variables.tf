variable "name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "production_listener_arn" {
  type = string
}

variable "blue_target_group_name" {
  type = string
}

variable "green_target_group_name" {
  type = string
}