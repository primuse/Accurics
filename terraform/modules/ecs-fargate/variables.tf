# VPC Variables

variable "vpc_id" {
}

variable "public_subnets" {
}

variable "private_subnets" {
}

# IAM Variables

variable "task_execution_role_arn" {
}

# ECS Service Variables

variable "service_name" {
}

variable "service_container_image" {
}

variable "service_container_cpu" {
}

variable "service_container_memory" {
}

variable "service_container_port" {
}

variable "service_host_port" {
}

variable "service_count" {
}

# ECS Cluster Variables

variable "cluster_name" {
  default = "ecs-cluster"
}

variable "cluster_capacity_provider" {
  default = "FARGATE_SPOT"
}

# Route53 Variables

variable "route53_hosted_zone_id" {
}

variable "route53_api_subdomain" {
}

variable "route53_api_global_subdomain" {
}

# Tags

variable "tag_environment" {
  default = "Development"
}
