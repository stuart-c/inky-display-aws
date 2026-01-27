data "aws_caller_identity" "current" {}


data "external" "git_details" {
  program = ["${path.module}/scripts/get_repo_details.sh"]
}


locals {
  account_id  = data.aws_caller_identity.current.account_id
  repo_name   = data.external.git_details.result.name
  repo_url    = data.external.git_details.result.url
  bucket_name = "${local.account_id}-${local.repo_name}-state"

  common_tags = {
    Repository = local.repo_url
    Type       = "Terraform"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

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
  version = "~> 3.0"

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

module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 5.0"

  name = "${local.bucket_name}-user"

  create_iam_access_key         = true
  create_iam_user_login_profile = false

  force_destroy = true

  tags = local.common_tags
}

data "aws_iam_policy_document" "terraform_state_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:Get*",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "dynamodb:Get*",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Describe*"
    ]
    effect    = "Allow"
    resources = [module.dynamodb_table.dynamodb_table_arn]
  }

  statement {
    actions = [
      "s3:ListAllMyBuckets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:Get*",
      "iam:List*"
    ]
    effect    = "Allow"
    resources = [module.iam_user.iam_user_arn]
  }
}

resource "aws_iam_user_policy" "terraform_state_policy" {
  name = "terraform-state-policy"
  user = module.iam_user.iam_user_name

  policy = data.aws_iam_policy_document.terraform_state_policy.json
}

resource "github_actions_secret" "aws_access_key_id" {
  repository      = local.repo_name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = module.iam_user.iam_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = local.repo_name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = module.iam_user.iam_access_key_secret
}
