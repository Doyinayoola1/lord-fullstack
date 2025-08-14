resource "aws_cloudfront_distribution" "s3-distribution" {
  origin {
    domain_name              = aws_s3_bucket.site-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site-oac.id
    origin_id                = "s3-site-bucket-${var.mod_environ}"

    s3_origin_config {
      origin_access_identity = "" # Not needed when using OAC
    }
  }


  enabled             = true
  is_ipv6_enabled     = true
  comment             = "cloudfront distribution for site bucket"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-site-bucket-${var.mod_environ}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "*.html"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-site-bucket-${var.mod_environ}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = var.mod_environ
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "site-oac" {
  name                              = "site-oac"
  description                       = "OAC for accessing s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}