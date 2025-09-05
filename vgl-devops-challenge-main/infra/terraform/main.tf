terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region
}

# Tags
locals {
  common_tags = {
    Project     = var.project
    Environment = var.env
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name = "${var.project}-${var.env}"
  cidr = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_nat_gateway = true
  single_nat_gateway = true
  tags = local.common_tags
}

# ECR
module "ecr_backend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 1.6"
  repository_name = var.ecr_repo_backend
  tags = local.common_tags
}
module "ecr_frontend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 1.6"
  repository_name = var.ecr_repo_frontend
  tags = local.common_tags
}

# ECS Cluster
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.7"
  cluster_name = "${var.project}-${var.env}"
  tags = local.common_tags
}

# ALB
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.11"
  name = "${var.project}-${var.env}"
  load_balancer_type = "application"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  tags = local.common_tags
}

# RDS MySQL (dev-friendly defaults)
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.6"
  identifier = "${var.project}-${var.env}"
  engine            = "mysql"
  engine_version    = "8.0"
  family            = "mysql8.0"
  instance_class    = var.rds_instance_class
  allocated_storage = 20
  username          = "admin"
  manage_master_user_password = true
  publicly_accessible = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = []
  multi_az = var.env == "production"
  tags = local.common_tags
}

# ElastiCache Redis (optional)
module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.8"
  engine               = "redis"
  family               = "redis7"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  vpc_id               = module.vpc.vpc_id
  subnets              = module.vpc.private_subnets
  apply_immediately    = true
  tags = local.common_tags
}

# Placeholder ECS Services (image tags set via variables/CI)
module "ecs_backend_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.7"
  name        = "backend"
  cluster_arn = module.ecs.cluster_arn
  launch_type = "FARGATE"
  cpu    = 256
  memory = 512
  desired_count = 2
  enable_execute_command = true

  container_definitions = [{
    name      = "backend"
    image     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo_backend}:${var.image_tag}"
    essential = true
    port_mappings = [{ containerPort = 8080 }]
    environment = [
      { name = "APP_ENV", value = var.env },
      { name = "DB_HOST", value = module.rds.db_instance_address },
      { name = "REDIS_HOST", value = "redis" }
    ]
    secrets = []
  }]

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = []
  assign_public_ip   = false
  tags = local.common_tags
}

module "ecs_frontend_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.7"
  name        = "frontend"
  cluster_arn = module.ecs.cluster_arn
  launch_type = "FARGATE"
  cpu    = 256
  memory = 512
  desired_count = 2

  container_definitions = [{
    name      = "frontend"
    image     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo_frontend}:${var.image_tag}"
    essential = true
    port_mappings = [{ containerPort = 5173 }]
  }]

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = []
  assign_public_ip   = false
  tags = local.common_tags
}
