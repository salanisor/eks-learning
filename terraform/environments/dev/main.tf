terraform {
  backend "s3" {
    bucket       = "eks-learning-tfstate-684177687615-us-east-1-an"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "eks-learning"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source       = "../../modules/vpc"
  cluster_name = var.cluster_name
  azs          = var.azs
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}