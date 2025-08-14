#This is the s3 bucket module for the site hosting
resource "aws_s3_bucket" "site_bucket" {
  bucket = "site_bucket_${var.mod_environ}"

  force_destroy = true

  tags = {
    Name        = "My bucket"
    Environment = "${var.mod_environ}"
  }
}

resource "aws_s3_bucket_logging" "site_logging" {
  bucket = aws_s3_bucket.site_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# resource "aws_s3_bucket_acl" "site_acl" {
#   bucket = aws_s3_bucket.site_bucket.id
#   access_control_policy {
#     grant {
#       grantee {
#         id   = data.aws_canonical_user_id.current.id
#         type = "CanonicalUser"
#       }
#       permission = "READ"
#     }
#     owner {
#       id = data.aws_canonical_user_id.current.id
#     }
#   }
# }
data "aws_caller_identity" "cloudfront_site" {}

resource "aws_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = { Service : "cloudfront.amazonaws.com" },
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.site_bucket.arn}/*"
        condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.cloudfront_site.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "site_versioning" {
  bucket = aws_s3_bucket.site_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "site_website" {
  bucket = aws_s3_bucket.site_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "log_bucket_${var.mod_environ}"

  force_destroy = false

  tags = {
    Environment = "${var.mod_environ}"
  }

}

resource "aws_s3_bucket_acl" "log_acl" {
  bucket = aws_s3_bucket.log_bucket.id

  acl = "log-delivery-write"
}

resource "aws_s3_bucket_versioning" "log_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "site_html" {
  bucket = aws_s3_bucket.site_bucket.id
  key    = "index.html"
  source = "../public/index.html"
  content_type = "text/html"
  content_disposition = "inline"

  tags = {
    Environment = "${var.mod_environ}"
  } 
}

resource "aws_s3_bucket" "s3_state_bucket" {
  bucket = "s3_state_bucket_${var.mod_environ}"

  force_destroy = false

  tags = {
    Environment = "${var.mod_environ}"
  }
  
}

resource "aws_s3_bucket_versioning" "s3_state_versioning" {
  bucket = aws_s3_bucket.s3_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state_block" {
  bucket                  = aws_s3_bucket.s3_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "s3_state" {}

resource "aws_s3_bucket_policy" "s3_state_policy" {
  bucket = aws_s3_bucket.s3_state_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3AccessForTerraform"
        Effect    = "Allow"
        Principal = { AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = ["s3:*"]
        Resource  = [
          "${aws_s3_bucket.s3_state_bucket.arn}",
          "${aws_s3_bucket.s3_state_bucket.arn}/*"
        ]
      }
    ]
  })
}