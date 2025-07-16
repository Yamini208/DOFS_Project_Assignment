terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-934787941896"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
