resource "aws_s3_bucket" "pp_bucket" {
  bucket = var.bucket_name
  tags = var.default_tags
}
