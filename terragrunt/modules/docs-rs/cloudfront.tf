// This file configures the docs.rs CloudFront distribution.

module "certificate" {
  source = "../acm-certificate"

  domains = [
    var.domain,
  ]
}

resource "aws_cloudfront_distribution" "webapp" {
  comment = var.domain

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2and3"

  aliases = [var.domain]
  viewer_certificate {
    acm_certificate_arn      = module.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "ec2"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = 900 // 15 minutes
    min_ttl     = 0
    max_ttl     = 31536000 // 1 year

    forwarded_values {
      headers = [
        // Allow detecting HTTPS from the webapp
        "CloudFront-Forwarded-Proto",
        // Allow detecting the domain name from the webapp
        "Host",
      ]
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    origin_id   = "ec2"
    domain_name = local.web_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // Stop CloudFront from caching error responses.
  //
  // Before we did this users were seeing error pages even after we resolved
  // outages, forcing us to invalidate the caches every time. The team agreed
  // the best solution was instead to stop CloudFront from caching error
  // responses altogether.
  dynamic "custom_error_response" {
    for_each = toset([400, 403, 404, 405, 414, 500, 501, 502, 503, 504])
    content {
      error_code            = custom_error_response.value
      error_caching_min_ttl = 0
    }
  }
}

resource "aws_route53_record" "webapp" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.webapp.domain_name]
}
