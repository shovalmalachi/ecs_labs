variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "container_port" {
  type = number
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/"
}
