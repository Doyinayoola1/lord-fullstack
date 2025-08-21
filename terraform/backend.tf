#This file is part of a Terraform configuration for deploying an S3 bucket with CloudFront distribution.
terraform {
  backend "s3" {
    bucket = "s3-state-bucket-${var.mod_environ}"
    key    = "${var.environ}/terraform.tfstate"
    region = var.region
    use_lockfile = true
    
  }
}