variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for created repositories"
  type        = map(string)
  default     = {}
}

variable "retain_count" {
  description = "Lifecycle policy: keep only the latest N images"
  type        = number
  default     = 3
}