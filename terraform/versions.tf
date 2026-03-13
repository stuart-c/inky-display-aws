terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
  }

  backend "s3" {
    bucket         = "485836911138-inky-display-aws-state"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "485836911138-inky-display-aws-state-lock"
    encrypt        = true
  }
}

