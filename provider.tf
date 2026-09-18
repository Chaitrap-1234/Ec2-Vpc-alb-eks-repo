terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ---------------------------------------------------------------------
  # OPTIONAL but RECOMMENDED for CI/CD (Jenkins + GitHub Actions):
  # Local state (the default when this block is left out) works, but
  # every pipeline run needs to see the SAME state file, otherwise one
  # system won't know what the other already created (double-create,
  # drift, etc). Uncomment this once you've created an S3 bucket
  # (and optionally a DynamoDB table for locking), then run:
  #   terraform init -migrate-state
  #
  # backend "s3" {
  #   bucket = "REPLACE-WITH-YOUR-UNIQUE-BUCKET-NAME"
  #   key    = "assignment/terraform.tfstate"
  #   region = "ap-south-1"
  #   # dynamodb_table = "terraform-locks"   # optional state locking
  #   # encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}
