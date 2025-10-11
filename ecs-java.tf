resource "aws_ecs_task_definition" "java_app" {
  family                   = "${local.name_prefix}-java-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "java-app"
      image     = "${module.ecr_java.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        },
        {
          containerPort = 9010
          hostPort      = 9010
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_java.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "java-app"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    },
    {
      name      = "jmx-exporter"
      image     = "bitnami/jmx-exporter:latest"
      essential = false

      portMappings = [
        {
          containerPort = 5556
          hostPort      = 5556
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SERVICE_PORT"
          value = "5556"
        }
      ]

      command = [
        "5556",
        "/opt/bitnami/jmx-exporter/example_configs/httpserver_sample_config.yml"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_java_sidecar.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "jmx-exporter"
        }
      }

      dependsOn = [
        {
          containerName = "java-app"
          condition     = "START"
        }
      ]
    },
    {
      name      = "cloudwatch-agent"
      image     = "amazon/cloudwatch-agent:latest"
      essential = false

      environment = [
        {
          name  = "CW_CONFIG_CONTENT"
          value = "{\"metrics\":{\"namespace\":\"JavaApp/JMX\",\"metrics_collected\":{\"prometheus\":{\"prometheus_config_path\":\"env:PROMETHEUS_CONFIG_CONTENT\",\"emf_processor\":{\"metric_declaration\":[{\"source_labels\":[\"job\"],\"label_matcher\":\"^jmx.*\",\"dimensions\":[[\"InstanceId\",\"job\"]],\"metric_selectors\":[\"^jvm_.*\",\"^java_.*\",\"^process_.*\"]}]}}}}}"
        },
        {
          name  = "PROMETHEUS_CONFIG_CONTENT"
          value = "global:\\n  scrape_interval: 1m\\nscrape_configs:\\n  - job_name: jmx\\n    static_configs:\\n      - targets:\\n          - localhost:5556"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_cloudwatch_agent.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "cloudwatch-agent"
        }
      }

      dependsOn = [
        {
          containerName = "jmx-exporter"
          condition     = "START"
        }
      ]
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "java_app" {
  name            = "${local.name_prefix}-java-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.java_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_java_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.java_app.arn
    container_name   = "java-app"
    container_port   = 8080
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.jmx_metrics.arn
    container_name   = "jmx-exporter"
    container_port   = 5556
  }

  depends_on = [
    aws_lb_listener.java_app,
    aws_lb_listener.jmx_metrics,
    aws_iam_role_policy_attachment.ecs_execution_role,
    aws_cloudwatch_log_group.ecs_java,
    aws_cloudwatch_log_group.ecs_java_sidecar,
    aws_cloudwatch_log_group.ecs_cloudwatch_agent
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_java" {
  name              = "/ecs/${local.name_prefix}-java"
  retention_in_days = var.log_retention_in_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_java_sidecar" {
  name              = "/ecs/${local.name_prefix}-jmx-exporter"
  retention_in_days = var.log_retention_in_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_cloudwatch_agent" {
  name              = "/ecs/${local.name_prefix}-cloudwatch-agent"
  retention_in_days = var.log_retention_in_days

  tags = local.common_tags
}

resource "aws_security_group" "ecs_java_tasks" {
  name        = "${local.name_prefix}-ecs-java-tasks"
  description = "Allow inbound access from the ALB to Java app and JMX exporter"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 5556
    to_port         = 5556
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-java-tasks"
  })
}

resource "aws_lb_target_group" "java_app" {
  name        = "${local.name_prefix}-java-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "jmx_metrics" {
  name        = "${local.name_prefix}-jmx-tg"
  port        = 5556
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "java_app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.java_app.arn
  }
}

resource "aws_lb_listener" "jmx_metrics" {
  load_balancer_arn = aws_lb.main.arn
  port              = "9090"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jmx_metrics.arn
  }
}

resource "aws_iam_role_policy" "ecs_task_cloudwatch_metrics_policy" {
  name = "${local.name_prefix}-ecs-task-cloudwatch-metrics-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "JavaApp/JMX"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${local.name_prefix}-*:*"
      }
    ]
  })
}
