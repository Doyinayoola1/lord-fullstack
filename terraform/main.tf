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
  region = var.region
  }


module "s3_cloudfront" {
  source = "./modules"

  mod_region = var.region
  mod_environ = var.environ
  
}