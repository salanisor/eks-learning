# ── Tenant onboarding ─────────────────────────────────────────────────────────
# Add new teams here. Each module block onboards one team.
# See README-tenant-onboarding.md for full instructions.
# ─────────────────────────────────────────────────────────────────────────────

module "team_test_app" {
  source = "../../modules/team"

  cluster_name   = var.cluster_name
  team_name      = "test-app"
  environment    = "dev"
  aws_account_id = "684177687615"
  repo_url       = var.github_repo_url
  ingress_order  = 20
  domain_name    = var.domain_name
  enable_hpa     = true
  hpa_min_replicas  = 2
  hpa_max_replicas  = 10
  hpa_cpu_target    = 70
  hpa_memory_target = 80

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

# ── AppProject — auto-generated from teams list ───────────────────────────────
# Add new team names to the teams list when onboarding
resource "local_file" "appproject" {
  content = templatefile("${path.module}/../../templates/gitops/appproject.yaml.tpl", {
    teams = ["test-app", "payments"]
  })
  filename = "${path.module}/../../../gitops/bootstrap/base/projects.yaml"
}
