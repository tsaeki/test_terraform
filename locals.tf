locals {
  # project
  project_name = "tsaeki"
  enviroment   = "dev"
  name_prefix  = "${local.project_name}-${local.enviroment}"
  
  # vpc
  vpc_name = "${local.project_name}-vpc"

  # common tags
  common_tags = {
    Project     = local.project_name
    Environment = local.enviroment
    ManagedBy   = "terraform"
  }

  # aurora
  aurora_name           = "${local.project_name}-aurora-db-postgres"
  aurora_engine         = "aurora-postgresql"
  aurora_engine_version = "16.4"
  aurora_instance_class = "db.t4g.medium"

  elasticache_name = "tsaeki-elasticache"

  # ecr
  ecr_repository_name = "tsaeki-test-ecr"

  function_name = "tsaeki-lambda"
  image_tag     = "latest"
}