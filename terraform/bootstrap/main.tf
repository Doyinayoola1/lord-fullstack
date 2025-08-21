#This creates the s3 bucket for the state file
#This is used by the backend configuration in Terraform to store the state file securely.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.5.0"
    }
  }
}

provider "aws" {
  # Configuration options for provider
  region = var.bootsrap_region
  }

resource "aws_s3_bucket" "s3-state-bucket" {
  bucket = "s3-state-bucket-doyin"

  force_destroy = false
  
}

resource "aws_s3_bucket_versioning" "s3-state-versioning" {
  bucket = aws_s3_bucket.s3-state-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state-block" {
  bucket                  = aws_s3_bucket.s3-state-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "s3-state" {}

resource "aws_s3_bucket_policy" "s3-state-policy" {
  bucket = aws_s3_bucket.s3-state-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3AccessForTerraform"
        Effect    = "Allow"
        Principal = { AWS : "arn:aws:iam::${data.aws_caller_identity.s3-state.account_id}:root" },
        Action    = ["s3:*"]
        Resource  = [
          "${aws_s3_bucket.s3-state-bucket.arn}",
          "${aws_s3_bucket.s3-state-bucket.arn}/*"
        ]
      }
    ]
  })
}