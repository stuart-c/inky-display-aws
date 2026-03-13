terraform {
  required_version = ">= 1.5.0"

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
    bucket       = "485836911138-terraform-state"
    key          = "inky-display-aws.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
