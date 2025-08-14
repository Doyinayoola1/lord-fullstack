#This is the s3 bucket module for the site hosting
resource "aws_s3_bucket" "site-bucket" {
  bucket = "site-bucket-${var.mod_environ}"

  force_destroy = true

  tags = {
    Name        = "My bucket"
    Environment = "${var.mod_environ}"
  }
}

resource "aws_s3_bucket_logging" "site-logging" {
  bucket = aws_s3_bucket.site-bucket.id

  target_bucket = aws_s3_bucket.log-bucket.id
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
data "aws_caller_identity" "cloudfront-site" {}

resource "aws_s3_bucket_policy" "site-policy" {
  bucket = aws_s3_bucket.site-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = { Service : "cloudfront.amazonaws.com" },
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.site-bucket.arn}/*"
        condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.cloudfront-site.account_id}:distribution/${aws_cloudfront_distribution.s3-distribution.id}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "site-versioning" {
  bucket = aws_s3_bucket.site-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "site-website" {
  bucket = aws_s3_bucket.site-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket" "log-bucket" {
  bucket = "doyin-log-bucket-${var.mod_environ}"

  force_destroy = false

  tags = {
    Environment = "${var.mod_environ}"
  }

}

resource "aws_s3_bucket_acl" "log-acl" {
  bucket = aws_s3_bucket.log-bucket.id

  acl = "log-delivery-write"
}

resource "aws_s3_bucket_versioning" "log-versioning" {
  bucket = aws_s3_bucket.log-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "site_html" {
  bucket = aws_s3_bucket.site-bucket.id
  key    = "index.html"
  source = "../public/index.html"
  content_type = "text/html"
  content_disposition = "inline"

  tags = {
    Environment = "${var.mod_environ}"
  } 
}

resource "aws_s3_bucket" "s3-state-bucket" {
  bucket = "s3-state-bucket-${var.mod_environ}"

  force_destroy = false

  tags = {
    Environment = "${var.mod_environ}"
  }
  
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