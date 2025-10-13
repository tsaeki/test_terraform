module "ecr_activemq" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${local.name_prefix}-activemq"

  repository_read_write_access_arns = [aws_iam_role.ecs_execution_role.arn]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest", "v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.common_tags
}
