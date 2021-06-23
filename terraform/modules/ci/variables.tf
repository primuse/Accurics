variable "service_name" {
  type        = string
  description = "The name of Service being deployed by the CI."
}

variable "ecr_repository_arn" {
  type        = string
  description = "The ARN of the ECR repository deployed to by teh CI."
}

variable "east_config" {
  type = object({
    codedeploy_application_name      = string
    codedeploy_deployment_group_name = string
    ecs_service_arn                  = string
    ecs_task_execution_role_arn      = string
    account_id                       = string
    region                           = string
  })
  description = "ECS and CodeDeploy configurations for the us-east-1 region."
}

variable "west_config" {
  type = object({
    codedeploy_application_name      = string
    codedeploy_deployment_group_name = string
    ecs_service_arn                  = string
    ecs_task_execution_role_arn      = string
    account_id                       = string
    region                           = string
  })
  description = "ECS and CodeDeploy configurations for the us-west-1 region."
}
