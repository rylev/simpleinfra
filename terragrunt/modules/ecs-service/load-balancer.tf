locals {
  top_level_domains = { for domain in var.domains : domain => join(".", reverse(slice(reverse(split(".", domain)), 0, 2))) }
}

module "certificate" {
  source  = "../acm-certificate"
  domains = var.domains
}

resource "aws_lb_listener_certificate" "service" {
  listener_arn    = var.cluster_config.lb_listener_arn
  certificate_arn = module.certificate.arn
}

resource "aws_lb_listener_rule" "service" {
  listener_arn = var.cluster_config.lb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    host_header {
      values = var.domains
    }
  }
}

resource "aws_lb_target_group" "service" {
  name        = var.name
  vpc_id      = var.cluster_config.vpc_id
  target_type = "ip"

  port     = var.http_port
  protocol = "HTTP"

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_route53_record" "service" {
  for_each = toset(var.domains)

  zone_id = var.zone_id
  name    = each.value
  type    = "CNAME"
  ttl     = 300
  records = [var.cluster_config.lb_dns_name]
}
