variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "lisa-environment" {
  description = "environment (development, staging, production)"
  type        = string
}

variable "lisa-s3-bucket-log" {
  description = "s3 bucket to store our site"
  type        = string
}

variable "lisa-s3-bucket-site" {
  description = "s3 bucket to store our site"
  type        = string
}
