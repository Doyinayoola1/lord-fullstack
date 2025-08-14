#This file is part of a Terraform configuration for deploying an S3 bucket with CloudFront distribution.
# terraform {
#   backend "s3" {
#     bucket = "aws_s3_bucket.site_bucket"
#     key    = "state/terraform.tfstate"
#     region = var.region
    
#   }
# }