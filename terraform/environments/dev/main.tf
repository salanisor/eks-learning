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

module "alb_controller" {
  source = "../../modules/alb-controller"

  cluster_name      = var.cluster_name
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "eks_auth" {
  source = "../../modules/eks-auth"

  cluster_name   = var.cluster_name
  node_role_arn  = module.eks.node_role_arn
  node_group_id  = module.eks.node_group_id
  admin_iam_arns = ["arn:aws:iam::684177687615:user/rosa-sa"]
}

module "argocd" {
  source = "../../modules/argocd"

  cluster_name    = var.cluster_name
  github_repo_url = var.github_repo_url

  depends_on = [module.eks]
}

module "external_secrets" {
  source       = "../../modules/external-secrets"
  cluster_name = var.cluster_name

  depends_on = [module.eks]
}

module "external_dns" {
  source = "../../modules/external-dns"

  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  depends_on = [module.eks]
}

module "team_test_app" {
  source = "../../modules/team"

  cluster_name   = var.cluster_name
  team_name      = "test-app"
  environment    = "dev"
  aws_account_id = "684177687615"
  repo_url       = var.github_repo_url
  ingress_order  = 20
  domain_name    = var.domain_name

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
}

module "team_payments" {
  source = "../../modules/team"

  cluster_name          = var.cluster_name
  team_name             = "payments"
  environment           = "dev"
  aws_account_id        = "684177687615"
  repo_url              = var.github_repo_url
  ingress_order         = 30
  domain_name           = var.domain_name
  enable_resource_quota = true
  resource_quota_cpu_requests    = "2"
  resource_quota_cpu_limits      = "4"
  resource_quota_memory_requests = "2Gi"
  resource_quota_memory_limits   = "4Gi"
  resource_quota_pods            = "10"

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
}

resource "local_file" "appproject" {
  content = templatefile("${path.module}/../../templates/gitops/appproject.yaml.tpl", {
    teams = ["test-app", "payments"]
  })
  filename = "${path.module}/../../../gitops/bootstrap/base/projects.yaml"
}
