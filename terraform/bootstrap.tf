data "aws_caller_identity" "current" {}


data "external" "git_details" {
  program = ["${path.module}/scripts/get_repo_details.sh"]
}


locals {
  account_id  = data.aws_caller_identity.current.account_id
  repo_name   = data.external.git_details.result.name
  repo_url    = data.external.git_details.result.url
  prefix_name = "${local.account_id}-${local.repo_name}"
  bucket_name = "${local.prefix_name}-state"

  common_tags = {
    Repository = local.repo_url
    Type       = "Terraform"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.10"

  bucket = local.bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.common_tags
}

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 5.5"

  name     = "${local.bucket_name}-lock"
  hash_key = "LockID"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = local.common_tags
}


