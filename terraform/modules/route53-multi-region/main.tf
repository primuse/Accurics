terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_route53_zone" "hosted_zone" {
  zone_id = var.route53_hosted_zone_id
}

resource "aws_route53_health_check" "api-a" {
  fqdn              = var.api_endpoint_a
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "30"

  tags = {
    Name = "api-a-health-check"
  }
}

resource "aws_route53_health_check" "api-b" {
  fqdn              = var.api_endpoint_b
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "30"

  tags = {
    Name = "api-b-health-check"
  }
}

resource "aws_route53_record" "api-a" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.route53_api_subdomain
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 1
  }

  health_check_id = aws_route53_health_check.api-a.id
  set_identifier  = "api-a"
  records         = [var.api_endpoint_a]
}

resource "aws_route53_record" "api-b" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.route53_api_subdomain
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 1
  }

  health_check_id = aws_route53_health_check.api-b.id
  set_identifier  = "api-b"
  records         = [var.api_endpoint_b]
}
