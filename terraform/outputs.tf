output "ecr_repository_url" {
  value = module.ecr-repository.repository_url
}

output "ecr_ci_access_key_id" {
  value = module.ci.ci_access_key_id
}

output "ecr_ci_access_secret_access_key" {
  value     = module.ci.ci_secret_access_key
  sensitive = true
}

output "ecs_service_name_east" {
  value = module.ecs-east.ecs_service_name
}

output "ecs_cluster_name_east" {
  value = module.ecs-east.ecs_cluster_name
}

output "codedeploy_application_name_east" {
  value = module.ecs-east.codedeploy_application_name
}

output "codedeploy_deployment_group_name_east" {
  value = module.ecs-east.codedeploy_deployment_group_name
}

output "ecs_service_name_west" {
  value = module.ecs-west.ecs_service_name
}

output "ecs_cluster_name_west" {
  value = module.ecs-west.ecs_cluster_name
}

output "codedeploy_application_name_west" {
  value = module.ecs-west.codedeploy_application_name
}

output "codedeploy_deployment_group_name_west" {
  value = module.ecs-west.codedeploy_deployment_group_name
}
