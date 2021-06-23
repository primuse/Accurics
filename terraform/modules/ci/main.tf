terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "aws_iam_user_policy" "ci_iam_policy" {
  name   = "${var.service_name}-ci-iam-policy"
  user   = aws_iam_user.ci_iam_user.name
  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"AllowPush",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
         ],
         "Resource":"${var.ecr_repository_arn}"
      },
      {
         "Sid":"GetAuthorizationToken",
         "Effect":"Allow",
         "Action":[
            "ecr:GetAuthorizationToken"
         ],
         "Resource":"*"
      },
      {
         "Sid":"RegisterTaskDefinition",
         "Effect":"Allow",
         "Action":[
            "ecs:RegisterTaskDefinition"
         ],
         "Resource":"*"
      },
      {
         "Sid":"PassRolesInTaskDefinition",
         "Effect":"Allow",
         "Action":[
            "iam:PassRole"
         ],
         "Resource":[
            "${var.east_config.ecs_task_execution_role_arn}",
            "${var.west_config.ecs_task_execution_role_arn}"
         ]
      },
      {
         "Sid":"DeployService",
         "Effect":"Allow",
         "Action":[
            "ecs:DescribeServices",
            "codedeploy:GetDeploymentGroup",
            "codedeploy:CreateDeployment",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision"
         ],
         "Resource":[
            "${var.east_config.ecs_service_arn}",
            "${var.west_config.ecs_service_arn}",
            "arn:aws:codedeploy:${var.east_config.region}:${var.east_config.account_id}:deploymentgroup:${var.east_config.codedeploy_application_name}/${var.east_config.codedeploy_deployment_group_name}",
            "arn:aws:codedeploy:${var.west_config.region}:${var.west_config.account_id}:deploymentgroup:${var.west_config.codedeploy_application_name}/${var.west_config.codedeploy_deployment_group_name}",
            "arn:aws:codedeploy:${var.east_config.region}:${var.east_config.account_id}:deploymentconfig:*",
            "arn:aws:codedeploy:${var.west_config.region}:${var.west_config.account_id}:deploymentconfig:*",
            "arn:aws:codedeploy:${var.east_config.region}:${var.east_config.account_id}:application:${var.east_config.codedeploy_application_name}",
            "arn:aws:codedeploy:${var.west_config.region}:${var.west_config.account_id}:application:${var.west_config.codedeploy_application_name}"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_user" "ci_iam_user" {
  name = "${var.service_name}-ci-iam-user"
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_iam_access_key" "ci_iam_user_credentials" {
  user = aws_iam_user.ci_iam_user.name
}