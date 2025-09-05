variable "project" { type = string }
variable "env"     { type = string }
variable "owner"   { type = string }
variable "region"  { type = string }
variable "account_id" { type = string }

variable "ecr_repo_backend"  { type = string }
variable "ecr_repo_frontend" { type = string }
variable "image_tag"         { type = string default = "latest" }

variable "vpc_cidr"         { type = string default = "10.0.0.0/16" }
variable "azs"              { type = list(string) }
variable "public_subnets"   { type = list(string) }
variable "private_subnets"  { type = list(string) }

variable "rds_instance_class" { type = string default = "db.t4g.micro" }
variable "redis_node_type"    { type = string default = "cache.t4g.micro" }
