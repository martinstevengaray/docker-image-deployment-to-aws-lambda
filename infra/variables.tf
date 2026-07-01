variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-2"
}

variable "function_name" {
  description = "Name of the Lambda function (and ECR repository)."
  type        = string
  default     = "containerized-lambda"
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
