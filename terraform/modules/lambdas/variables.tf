variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.9"
}

variable "filename" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}