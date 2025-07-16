variable "github_repo" {
  description = "GitHub repository path"
  type        = string
  default     = "Yamini208/DOFS_Project_Assignment"
}

variable "aws_region" {
  description = "AWS region for CodeBuild"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for bucket naming)"
  type        = string
  default     = "order-fulfillment"
}
