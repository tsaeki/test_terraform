
terraform {
  required_version = "~> 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "tsaeki-20241115-terraform-state"
    key    = "terraform_20241226.tfstate"
    region = "ap-northeast-1"
  }
}

# Get current AWS account ID
# data "aws_caller_identity" "current" {}