module "ota_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${local.prefix_name}-ota"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  block_public_acls       = false
  block_public_policy     = false # Kept false to avoid conflicts, though we rely on ACLs now
  ignore_public_acls      = false
  restrict_public_buckets = false

  tags = local.common_tags
}

module "object_index" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "~> 3.0"

  bucket       = module.ota_s3_bucket.s3_bucket_id
  key          = "index.html"
  file_source  = "${path.module}/www/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/www/index.html")
  acl          = "public-read"
}

module "object_error" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "~> 3.0"

  bucket       = module.ota_s3_bucket.s3_bucket_id
  key          = "error.html"
  file_source  = "${path.module}/www/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/www/error.html")
  acl          = "public-read"
}

module "ota_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 5.0"

  name = "${local.prefix_name}-ota-upload"

  create_iam_access_key         = true
  create_iam_user_login_profile = false

  force_destroy = true

  tags = local.common_tags
}

data "aws_iam_policy_document" "ota_upload_policy" {
  statement {
    sid = "AllowS3Upload"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket", # Often helpful for sync operations
      "s3:GetBucketLocation"
    ]
    effect = "Allow"
    resources = [
      module.ota_s3_bucket.s3_bucket_arn,
      "${module.ota_s3_bucket.s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "ota_upload_user_policy" {
  name = "ota-upload-policy"
  user = module.ota_iam_user.iam_user_name

  policy = data.aws_iam_policy_document.ota_upload_policy.json
}

# Secrets stored in inky-display repository
resource "github_actions_secret" "ota_aws_access_key_id" {
  repository      = "inky-display"
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = module.ota_iam_user.iam_access_key_id
}

resource "github_actions_secret" "ota_aws_secret_access_key" {
  repository      = "inky-display"
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = module.ota_iam_user.iam_access_key_secret
}

resource "github_actions_secret" "ota_url" {
  repository      = "inky-display"
  secret_name     = "OTA_URL"
  plaintext_value = module.ota_s3_bucket.s3_bucket_website_endpoint
}

resource "github_actions_secret" "ota_bucket" {
  repository      = "inky-display"
  secret_name     = "OTA_BUCKET"
  plaintext_value = module.ota_s3_bucket.s3_bucket_id
}
