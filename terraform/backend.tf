#This file is part of a Terraform configuration for deploying an S3 bucket with CloudFront distribution.
terraform {
  backend "s3" {
    
    use_lockfile = true
    encrypt = true
  }
}