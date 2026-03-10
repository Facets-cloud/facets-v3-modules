locals {
  spec = var.instance.spec

  container_image   = local.spec.container_image
  container_port    = try(local.spec.container_port, 3000)
  cpu               = try(local.spec.cpu, 256)
  memory            = try(local.spec.memory, 512)
  desired_count     = try(local.spec.desired_count, 1)
  health_check_path = try(local.spec.health_check_path, "/healthz")
  env_vars          = try(local.spec.env, {})
  assign_public_ip  = try(local.spec.assign_public_ip, true)
  path_pattern      = try(local.spec.path_pattern, "/*")
  priority          = try(local.spec.priority, 100)

  # ALB attributes from shared ALB input
  alb_listener_arn   = var.inputs.alb.attributes.listener_arn
  alb_security_group = var.inputs.alb.attributes.security_group_id

  name_prefix = "${var.instance_name}-${var.environment.name}"
  vpc_id      = var.inputs.network_details.attributes.vpc_id
  public_ids  = var.inputs.network_details.attributes.public_subnet_ids
  private_ids = var.inputs.network_details.attributes.private_subnet_ids

  tags = merge(var.environment.cloud_tags, {
    Name          = var.instance_name
    environment   = var.environment.name
    resource_type = var.instance.kind
  })
}

data "aws_region" "current" {}

# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = local.name_prefix
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --- CloudWatch Log Group ---

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 14
  tags              = local.tags
}

# --- IAM: Task Execution Role ---

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name_prefix}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- IAM: Task Role ---

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = local.tags
}

locals {
  iam_statements = try(local.spec.iam_statements, [])
}

data "aws_iam_policy_document" "task_custom" {
  count = length(local.iam_statements) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = local.iam_statements
    content {
      effect    = try(statement.value.effect, "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "task_custom" {
  count  = length(local.iam_statements) > 0 ? 1 : 0
  name   = "${local.name_prefix}-task-custom"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_custom[0].json
}

# --- Task Security Group (references ALB SG from input) ---

resource "aws_security_group" "task" {
  name_prefix = "${local.name_prefix}-task-"
  vpc_id      = local.vpc_id
  tags        = local.tags

  ingress {
    from_port       = local.container_port
    to_port         = local.container_port
    protocol        = "tcp"
    security_groups = [local.alb_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
}

# --- Target Group ---

resource "aws_lb_target_group" "main" {
  name        = local.name_prefix
  port        = local.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"
  tags        = local.tags

  health_check {
    path                = local.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
}

# --- ALB Listener Rule (path-based routing) ---

resource "aws_lb_listener_rule" "main" {
  listener_arn = local.alb_listener_arn
  priority     = local.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = [local.path_pattern]
    }
  }
}

# --- Task Definition ---

resource "aws_ecs_task_definition" "main" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(local.cpu)
  memory                   = tostring(local.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  tags                     = local.tags

  container_definitions = jsonencode([{
    name      = var.instance_name
    image     = local.container_image
    essential = true

    portMappings = [{
      containerPort = local.container_port
      protocol      = "tcp"
    }]

    environment = [
      for k, v in local.env_vars : { name = k, value = tostring(v) }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# --- ECS Service ---

resource "aws_ecs_service" "main" {
  name            = var.instance_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = local.desired_count
  launch_type     = "FARGATE"
  tags            = local.tags

  network_configuration {
    subnets          = local.assign_public_ip ? local.public_ids : local.private_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = local.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.instance_name
    container_port   = local.container_port
  }

  depends_on = [aws_lb_listener_rule.main]
}
