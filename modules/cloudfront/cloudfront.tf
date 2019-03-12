data "aws_acm_certificate" "sample_acm" {
  domain = "${var.domain}"
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.domain}"
  acl    = "private"

  tags {
    Enviroment = "${terraform.workspace}"
  }
}

resource "aws_cloudfront_distribution" "this" {
  # API
  origin {
    domain_name = "${var.dns_name}"
    origin_id   = "${terraform.workspace}-api-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  aliases = ["${var.domain}"]
  enabled = true
  comment = "${terraform.workspace}-comment"

  default_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${terraform.workspace}-api-origin"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Host", "Referer", "X-Forwarded-For", "User-Agent"]

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.sample_acm.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  logging_config {
    bucket = "${aws_s3_bucket.this.bucket_domain_name}"
  }

  lifecycle {
    ignore_changes = ["default_cache_behavior"]
  }

  tags {
    Enviroment = "${terraform.workspace}"
  }
}
