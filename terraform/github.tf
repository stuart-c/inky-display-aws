module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 5.0"

  name = "${local.bucket_name}-user"

  create_iam_access_key         = true
  create_iam_user_login_profile = false

  force_destroy = true

  tags = local.common_tags
}

data "aws_iam_policy_document" "terraform_base" {
  statement {
    sid = "AllowS3Read"
    actions = [
      "s3:ListBucket",
      "s3:Get*"
    ]
    effect = "Allow"
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid = "AllowDynamoDBLocking"
    actions = [
      "dynamodb:List*",
      "dynamodb:Get*",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Describe*"
    ]
    effect    = "Allow"
    resources = [module.dynamodb_table.dynamodb_table_arn]
  }

  statement {
    sid = "AllowS3ListBuckets"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "AllowIAMRead"
    actions = [
      "iam:Get*",
      "iam:List*"
    ]
    effect = "Allow"
    resources = [
      module.iam_user.iam_user_arn,
      module.iam_user_apply.iam_user_arn,
      "arn:aws:iam::${local.account_id}:policy/terraform-apply-policy"
    ]
  }
}

resource "aws_iam_user_policy" "terraform_state_policy" {
  name = "terraform-state-policy"
  user = module.iam_user.iam_user_name

  policy = data.aws_iam_policy_document.terraform_base.json
}

module "iam_user_apply" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 5.0"

  name = "${local.bucket_name}-user-apply"

  create_iam_access_key         = true
  create_iam_user_login_profile = false

  force_destroy = true

  tags = local.common_tags
}

data "aws_iam_policy_document" "terraform_apply" {
  statement {
    sid = "AllowS3Write"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutBucketTagging"
    ]
    effect = "Allow"
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid = "AllowIAMWrite"
    actions = [
      "iam:*"
    ]
    effect = "Allow"
    resources = [
      module.iam_user.iam_user_arn,
      module.iam_user_apply.iam_user_arn
    ]
  }

  statement {
    sid = "AllowDynamoDBWrite"
    actions = [
      "dynamodb:TagResource",
      "dynamodb:UntagResource"
    ]
    effect = "Allow"
    resources = [
      module.dynamodb_table.dynamodb_table_arn
    ]
  }

  statement {
    sid = "AllowOTABucket"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucket*",
      "s3:Get*",
      "s3:ListBucket",
      "s3:PutLifecycleConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${local.account_id}-inky-display-ota",
      "arn:aws:s3:::${local.account_id}-inky-display-ota/*"
    ]
  }

  statement {
    sid = "AllowOTAIAMUser"
    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:GetUser",
      "iam:ListUsers",
      "iam:UpdateUser",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:GetAccessKey",
      "iam:ListAccessKeys",
      "iam:PutUserPolicy",
      "iam:DeleteUserPolicy",
      "iam:GetUserPolicy",
      "iam:ListUserPolicies",
      "iam:TagUser"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:iam::${local.account_id}:user/ota-upload-user"
    ]
  }
}

data "aws_iam_policy_document" "terraform_apply_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.terraform_base.json,
    data.aws_iam_policy_document.terraform_apply.json
  ]
}

resource "aws_iam_policy" "terraform_apply_policy" {
  name   = "terraform-apply-policy"
  policy = data.aws_iam_policy_document.terraform_apply_combined.json
}

resource "aws_iam_user_policy_attachment" "terraform_apply_policy_attachment" {
  user       = module.iam_user_apply.iam_user_name
  policy_arn = aws_iam_policy.terraform_apply_policy.arn
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

resource "github_actions_secret" "aws_access_key_id_apply" {
  repository      = local.repo_name
  secret_name     = "AWS_ACCESS_KEY_ID_APPLY"
  plaintext_value = module.iam_user_apply.iam_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key_apply" {
  repository      = local.repo_name
  secret_name     = "AWS_SECRET_ACCESS_KEY_APPLY"
  plaintext_value = module.iam_user_apply.iam_access_key_secret
}
