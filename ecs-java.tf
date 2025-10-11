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
      image     = "${module.ecr_java.repository_url}:jmx-exporter"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        },
        {
          containerPort = 9404
          hostPort      = 9404
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "production"
        }
      ]

      dockerLabels = {
        ECS_PROMETHEUS_EXPORTER_PORT = "9404"
        Java_EMF_Metrics            = "true"
      }

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
      name      = "cloudwatch-agent"
      image     = "amazon/cloudwatch-agent:latest"
      essential = false

      secrets = [
        {
          name      = "CW_CONFIG_CONTENT"
          valueFrom = aws_ssm_parameter.cloudwatch_agent_config.arn
        },
        {
          name      = "PROMETHEUS_CONFIG_CONTENT"
          valueFrom = aws_ssm_parameter.prometheus_config.arn
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
          containerName = "java-app"
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

  depends_on = [
    aws_lb_listener.java_app,
    aws_iam_role_policy_attachment.ecs_execution_role,
    aws_iam_role_policy.ecs_execution_ssm_policy,
    aws_cloudwatch_log_group.ecs_java,
    aws_cloudwatch_log_group.ecs_cloudwatch_agent,
    aws_ssm_parameter.cloudwatch_agent_config,
    aws_ssm_parameter.prometheus_config
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_java" {
  name              = "/ecs/${local.name_prefix}-java"
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
  description = "Allow inbound access from the ALB to Java app"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
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

resource "aws_lb_listener" "java_app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.java_app.arn
  }
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "/${local.enviroment}/cloudwatch-agent/prometheus-config"
  description = "CloudWatch Agent configuration for Prometheus metrics scraping"
  type        = "String"
  value = jsonencode({
    logs = {
      metrics_collected = {
        prometheus = {
          cluster_name = aws_ecs_cluster.main.name
          log_group_name = "/aws/ecs/containerinsights/${aws_ecs_cluster.main.name}/prometheus"
          prometheus_config_path = "env:PROMETHEUS_CONFIG_CONTENT"
          emf_processor = {
            metric_declaration = [
              {
                source_labels = ["job"]
                label_matcher = "^java-jmx$"
                dimensions = [
                  ["ClusterName", "TaskDefinitionFamily"],
                  ["ClusterName", "TaskDefinitionFamily", "gc"]
                ]
                metric_selectors = [
                  "^jvm_memory_.*",
                  "^jvm_threads_.*",
                  "^jvm_gc_.*",
                  "^jvm_classloading_.*",
                  "^jvm_runtime_.*"
                ]
              }
            ]
          }
        }
      }
    }
  })

  tags = local.common_tags
}

resource "aws_ssm_parameter" "prometheus_config" {
  name        = "/${local.enviroment}/prometheus/config"
  description = "Prometheus scrape configuration for JMX metrics"
  type        = "String"
  value = yamlencode({
    global = {
      scrape_interval = "1m"
      scrape_timeout  = "10s"
    }
    scrape_configs = [
      {
        job_name = "java-jmx"
        static_configs = [
          {
            targets = ["localhost:9404"]
            labels = {
              ClusterName         = aws_ecs_cluster.main.name
              TaskDefinitionFamily = "${local.name_prefix}-java-app"
            }
          }
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ecs_execution_ssm_policy" {
  name = "${local.name_prefix}-ecs-execution-ssm-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.cloudwatch_agent_config.arn,
          aws_ssm_parameter.prometheus_config.arn
        ]
      }
    ]
  })
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
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${local.name_prefix}-*:*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ecs/containerinsights/${aws_ecs_cluster.main.name}/*:*"
        ]
      }
    ]
  })
}
