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
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

module "alb_controller" {
  source = "../../modules/alb-controller"

  cluster_name      = var.cluster_name
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "external_secrets" {
  source       = "../../modules/external-secrets"
  cluster_name = var.cluster_name
}

module "team_test_app" {
  source         = "../../modules/team"
  cluster_name   = var.cluster_name
  team_name      = "test-app"
  environment    = "dev"
  aws_account_id = "684177687615"

  app_policy_statements = [
    {
      Sid    = "AllowReadOnlyS3Access"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = "*"
    }
  ]

  depends_on = [module.external_secrets]
}

module "eks_auth" {
  source = "../../modules/eks-auth"

  cluster_name   = var.cluster_name
  node_role_arn  = module.eks.node_role_arn
  admin_iam_arns = ["arn:aws:iam::684177687615:user/rosa-sa"]
}