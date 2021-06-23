output "route53_endpoint" {
  value = aws_route53_record.api.name
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "ecs_service_arn" {
  value = aws_ecs_service.service.id
}

output "ecs_cluster_name" {
  value = module.ecs.this_ecs_cluster_name
}

output "codedeploy_application_name" {
  value = aws_codedeploy_app.codedeploy_app.name
}

output "codedeploy_application_arn" {
  value = aws_codedeploy_app.codedeploy_app.id
}

output "codedeploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
}

