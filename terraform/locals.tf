data "aws_caller_identity" "current" {}

data "external" "git_details" {
  program = ["${path.module}/scripts/get_repo_details.sh"]
}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  repo_name   = data.external.git_details.result.name
  repo_url    = data.external.git_details.result.url
  prefix_name = "${local.account_id}-${local.repo_name}"

  common_tags = {
    Repository = local.repo_url
    Type       = "Terraform"
  }
}
