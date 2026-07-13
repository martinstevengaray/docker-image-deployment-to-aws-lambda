variable "region" {
  description = "AWS region to deploy into. Passed in by deploy.sh / CI (the single source of truth), not defaulted here."
  type        = string
  nullable    = false
}

variable "lambda_function_name" {
  description = "Name of the Lambda function. Passed in by deploy.sh / CI (the single source of truth), not defaulted here."
  type        = string
  nullable    = false
}

variable "ecr_repository" {
  description = "Name of the ECR repository holding the container image. Passed in by deploy.sh / CI (the single source of truth), not defaulted here."
  type        = string
  nullable    = false
}

variable "architecture" {
  description = "Lambda/container architecture. arm64 matches Apple Silicon and avoids emulation."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be either \"arm64\" or \"x86_64\"."
  }
}

variable "memory_size" {
  description = "Lambda memory (MB)."
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda timeout (seconds)."
  type        = number
  default     = 15
}

variable "reserved_concurrent_executions" {
  description = "Maximum number of concurrent Lambda invocations. -1 removes the limit."
  type        = number
  default     = -1
}

variable "image_uri" {
  description = "Full ECR image URI (repo:tag) to deploy. Built and pushed by deploy.sh / CI, then passed in at apply time — Terraform does not build the image."
  type        = string
  nullable    = false
}
