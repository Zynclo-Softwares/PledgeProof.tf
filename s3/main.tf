resource "aws_s3_bucket" "static_bucket" {
  bucket = var.bucket_name
  tags = var.default_tags
}
