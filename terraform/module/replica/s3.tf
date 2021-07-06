resource "aws_s3_bucket" "replica" {
  bucket = "terraform-exaple-bucket-s3-trigger-lambda-replica"
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "replica" {
  bucket = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
