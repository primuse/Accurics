locals {
  service_name           = "nginx"
  service_container_port = 80
  service_host_port      = 80
  service_memory         = 512
  service_cpu            = 256
  service_count          = 3

  api_global_subdomain = "api"

  elasticsearch_version              = "7.9"
  elasticsearch_instance_type        = "t3.small.elasticsearch"
  elasticsearch_instance_count       = 3
  elasticsearch_instance_volume_size = 50
  elasticsearch_az_count             = 3
  route53_hosted_zone_id             = "Z3IE2PS0YRQ77E" # bptests.com
}
