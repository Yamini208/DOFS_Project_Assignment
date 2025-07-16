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
