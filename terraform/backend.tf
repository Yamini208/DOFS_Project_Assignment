resource "aws_s3_bucket" "s3_tf_backend" {
  bucket        = "terraform-state-dev-934787941896"
  force_destroy = false

  tags = {
    Name        = "TerraformState"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "s3_tf_backend_versioning" {
  bucket = aws_s3_bucket.s3_tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_tf_backend_encryption" {
  bucket = aws_s3_bucket.s3_tf_backend.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
