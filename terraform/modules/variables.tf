variable "mod_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "mod_environ" {
  description = "The environment for the deployment (e.g., development, staging, production)"
  type        = string
}