terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "2.5.0"

  name               = var.cluster_name
  container_insights = true
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    capacity_provider = var.cluster_capacity_provider
  }

  tags = {
    Environment = var.tag_environment
  }
}

data "aws_region" "current" {
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_route53_zone" "hosted_zone" {
  zone_id = var.route53_hosted_zone_id
}

data "template_file" "service" {
  template = file("${path.module}/templates/service.json.tpl")
  vars = {
    name           = var.service_name
    image          = var.service_container_image
    container_port = var.service_container_port
    host_port      = var.service_host_port
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "service"
  container_definitions    = data.template_file.service.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.service_container_cpu
  memory                   = var.service_container_memory
  execution_role_arn       = var.task_execution_role_arn

  lifecycle {
    ignore_changes = [container_definitions, cpu, memory]
  }
}



resource "aws_ecs_service" "service" {
  name            = "${var.service_name}-service"
  cluster         = module.ecs.this_ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = var.service_name
    container_port   = var.service_container_port
  }

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs-service.id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [load_balancer, task_definition]
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "${var.service_name}-${data.aws_region.current.name}-codedeploy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_role.name
}

resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "ECS"
  name             = var.service_name
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = aws_codedeploy_app.codedeploy_app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.service_name}-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = module.ecs.this_ecs_cluster_name
    service_name = aws_ecs_service.service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.http-listener.arn]
      }

      target_group {
        name = aws_alb_target_group.blue.name
      }

      target_group {
        name = aws_alb_target_group.green.name
      }
    }
  }
}

resource "aws_alb" "alb" {
  name               = "alb-${var.service_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  tags = {
    Environment = var.tag_environment
  }
}

resource "aws_alb_target_group" "blue" {
  name        = "tg-${var.service_name}-blue"
  port        = var.service_host_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  depends_on = [aws_alb.alb]
}

resource "aws_alb_target_group" "green" {
  name        = "tg-${var.service_name}-green"
  port        = var.service_host_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  depends_on = [aws_alb.alb]
}

resource "aws_alb_listener" "http-listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_security_group" "ecs-service" {
  name        = "vpc-ingress-${var.service_name}"
  description = "ECS Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "VPC Ingress"
    from_port   = var.service_host_port
    to_port     = var.service_host_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-ingress-${var.service_name}"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-${var.service_name}"
  description = "ALB Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["<cidr>"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-${var.service_name}"
  }
}

resource "aws_acm_certificate" "api" {
  domain_name       = aws_route53_record.api.name
  validation_method = "DNS"

  subject_alternative_names = ["${var.route53_api_global_subdomain}.${data.aws_route53_zone.hosted_zone.name}"]

  tags = {
    Environment = var.tag_environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_record : record.fqdn]
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.route53_api_subdomain}.${data.aws_route53_zone.hosted_zone.name}"
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
  }
}
