locals {
  default_attributes = {
    cluster_arn         = aws_ecs_cluster.main.arn
    service_arn         = aws_ecs_service.main.id
    service_name        = aws_ecs_service.main.name
    task_definition_arn = aws_ecs_task_definition.main.arn
    target_group_arn    = aws_lb_target_group.main.arn
    security_group_id   = aws_security_group.task.id
    log_group_name      = aws_cloudwatch_log_group.main.name
  }
}

output "default" {
  value = {
    attributes = local.default_attributes
    interfaces = {}
  }
}
