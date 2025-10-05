module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = local.vpc_name
  cidr = "10.0.0.0/16"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"] # Added bastion subnet
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]
  elasticache_subnets = ["10.0.31.0/24", "10.0.32.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  create_database_subnet_group = true
  database_subnet_group_name   = "${local.project_name}-db-subnet-group"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

