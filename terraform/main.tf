/////////////////////////////
///// Data Sources

data "aws_region" "east" {
  provider = aws.east
}

data "aws_region" "west" {
  provider = aws.west
}

data "aws_caller_identity" "current" {
  provider = aws.east
}

/////////////////////////////
///// Modules

module "vpc-east" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name = "ecs-fargate-east"
  cidr = "10.70.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  private_subnets = ["10.70.1.0/24", "10.70.2.0/24", "10.70.3.0/24", "10.70.4.0/24", "10.70.5.0/24", "10.70.6.0/24"]
  public_subnets  = ["10.70.101.0/24", "10.70.102.0/24", "10.70.103.0/24", "10.70.104.0/24", "10.70.105.0/24", "10.70.106.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Environment = "dev-east"
  }

  providers = {
    aws = aws.east
  }
}

module "vpc-west" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ecs-fargate-west"
  cidr = "10.80.0.0/16"

  azs             = ["us-west-1a", "us-west-1c"]
  private_subnets = ["10.80.1.0/24", "10.80.2.0/24"]
  public_subnets  = ["10.80.101.0/24", "10.80.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Environment = "dev-west"
  }

  providers = {
    aws = aws.west
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.service_name}-ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  provider           = aws.east
}

resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name

  provider = aws.east
}

module "ecs-east" {
  source = "./modules/ecs-fargate"

  service_name             = local.service_name
  service_container_image  = "${module.ecr-repository.repository_url}:latest"
  service_container_cpu    = local.service_cpu
  service_container_memory = local.service_memory
  service_container_port   = local.service_container_port
  service_host_port        = local.service_host_port
  service_count            = local.service_count

  task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  route53_hosted_zone_id       = local.route53_hosted_zone_id
  route53_api_global_subdomain = local.api_global_subdomain
  route53_api_subdomain        = "api-us-east"

  vpc_id          = module.vpc-east.vpc_id
  private_subnets = module.vpc-east.private_subnets
  public_subnets  = module.vpc-east.public_subnets

  tag_environment = "dev-east"

  providers = {
    aws = aws.east
  }
}

module "ecs-west" {
  source = "./modules/ecs-fargate"

  service_name             = local.service_name
  service_container_image  = "${module.ecr-repository.repository_url}:latest"
  service_container_cpu    = local.service_cpu
  service_container_memory = local.service_memory
  service_container_port   = local.service_container_port
  service_host_port        = local.service_host_port
  service_count            = local.service_count

  task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  route53_hosted_zone_id       = local.route53_hosted_zone_id
  route53_api_global_subdomain = local.api_global_subdomain
  route53_api_subdomain        = "api-us-west"

  vpc_id          = module.vpc-west.vpc_id
  private_subnets = module.vpc-west.private_subnets
  public_subnets  = module.vpc-west.public_subnets

  tag_environment = "dev-west"

  providers = {
    aws = aws.west
  }
}

module "route53-multi-region" {
  source = "./modules/route53-multi-region"

  api_endpoint_a = module.ecs-east.route53_endpoint
  api_endpoint_b = module.ecs-west.route53_endpoint

  route53_hosted_zone_id = local.route53_hosted_zone_id
  route53_api_subdomain  = local.api_global_subdomain

  providers = {
    aws = aws.east
  }
}

module "ecr-repository" {
  source = "./modules/ecr-repository"
  name   = local.service_name

  providers = {
    aws = aws.east
  }
}

module "ci" {
  source = "./modules/ci"

  service_name       = local.service_name
  ecr_repository_arn = module.ecr-repository.repository_arn

  east_config = {
    codedeploy_application_arn       = module.ecs-east.codedeploy_application_arn
    codedeploy_application_name      = module.ecs-east.codedeploy_application_name
    codedeploy_deployment_group_name = module.ecs-east.codedeploy_deployment_group_name
    ecs_service_arn                  = module.ecs-east.ecs_service_arn
    ecs_task_execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
    account_id                       = data.aws_caller_identity.current.account_id
    region                           = data.aws_region.east.name
  }

  west_config = {
    codedeploy_application_arn       = module.ecs-west.codedeploy_application_arn
    codedeploy_application_name      = module.ecs-west.codedeploy_application_name
    codedeploy_deployment_group_name = module.ecs-west.codedeploy_deployment_group_name
    ecs_service_arn                  = module.ecs-west.ecs_service_arn
    ecs_task_execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
    account_id                       = data.aws_caller_identity.current.account_id
    region                           = data.aws_region.west.name
  }

  providers = {
    aws = aws.east
  }
}
