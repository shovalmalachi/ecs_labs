variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "force_delete" {
  description = "Allow deletion of a non-empty ECR repository"
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Scan container images when pushed"
  type        = bool
  default     = true
}