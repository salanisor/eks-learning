terraform {
  backend "s3" {
    bucket         = "eks-learning-tfstate-684177687615-us-east-1-an"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-learning-tfstate-lock"
    encrypt        = true
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
}