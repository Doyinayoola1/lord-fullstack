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

data "aws_caller_identity" "cloudfront-site" {}

resource "aws_s3_bucket_policy" "site-policy" {
  bucket = aws_s3_bucket.site-bucket.id
  depends_on = [aws_cloudfront_distribution.s3-distribution]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = { Service : "cloudfront.amazonaws.com" },
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.site-bucket.arn}/*"
        Condition = {
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

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.log-bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "sess" { arn = data.aws_caller_identity.current.arn }


resource "aws_s3_bucket_policy" "log-site-policy" {
  bucket = aws_s3_bucket.log-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
       {
        Sid = "Allowloggingaccess"
        Effect = "Allow"
        Principal = { Service: "logging.s3.amazonaws.com" },
        Action = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.log-bucket.arn}/log/*"
        # Condition = {
        #   StringEquals = {
        #     "aws:SourceArn" = "aws_cloudfront_distribution.s3-distribution.arn"
        #   }
        # }
      },
      {
        Sid: "CIWriteLogs",
        Effect: "Allow",
        Principal: { AWS = data.aws_iam_session_context.sess.issuer_arn }, # the role your workflow assumed
        Action: ["s3:PutObject","s3:GetObject","s3:ListBucket"],
        Resource: [
          aws_s3_bucket.log-bucket.arn,
          "${aws_s3_bucket.log-bucket.arn}/*"
        ]
      }
    ]
  })
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

# data "aws_caller_identity" "current" {}

# #gets the current user name from the aws id
# data "aws_iam_user" "current_user" {
#   user_name = data.aws_caller_identity.current.user_id
# }

# resource "aws_iam_policy" "logging-policy" {
#   name        = "logging-policy"
#   path        = "/"
#   description = "My logging policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "s3:ListBucket",
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:s3:::${aws_s3_bucket.log-bucket.id}"
#       },
#       {
#         Action = [
#           "s3:GetObject",
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:s3:::${aws_s3_bucket.log-bucket.id}/*"
#       }
#     ]
#   })
# }

#This policy that allows the IAM user to access the logging bucket
# resource "aws_iam_user_policy_attachment" "log-policy-attachment" {
#   user       = data.aws_iam_user.current_user.user_name
#   policy_arn = aws_iam_policy.logging-policy.arn
# }