component "s3" {
  for_each = var.regions
  source   = "./s3"
  inputs = {
    # Unique bucket name (S3 names are global)
    bucket_name = "pledgeproof-${each.value}"
  }
  providers = { aws = provider.aws.configurations[each.value] }
}
