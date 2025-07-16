resource "aws_codebuild_project" "terraform_build" {
  name          = "terraform-build"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
  environment {
  compute_type                = "BUILD_GENERAL1_SMALL"
  image                       = "aws/codebuild/standard:5.0"
  type                        = "LINUX_CONTAINER"
  privileged_mode             = true

  environment_variable {
    name  = "AWS_REGION"
    value = var.aws_region
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.github_repo}.git"
    buildspec       = "buildspec.yml"
  }
}
