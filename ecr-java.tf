module "ecr_java" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${local.project_name}-java-ecr"
  repository_image_tag_mutability = "MUTABLE"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 3 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 3
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.common_tags
}

output "ecr_java_repository_url" {
  description = "URL of the Java ECR repository"
  value       = module.ecr_java.repository_url
}
