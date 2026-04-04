data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

data "aws_iam_policy_document" "eso_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:role/${var.cluster_name}-eso"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# ── Kubernetes namespace ──────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.team_name
    labels = {
      team        = var.team_name
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# ── ESO IAM role — scoped to this team's secret path only ─────────────────────
resource "aws_iam_role" "eso" {
  name               = "${var.cluster_name}-eso-${var.team_name}"
  assume_role_policy = data.aws_iam_policy_document.eso_role_trust.json

  tags = {
    Name        = "${var.cluster_name}-eso-${var.team_name}"
    Team        = var.team_name
    Environment = var.environment
    Purpose     = "external-secrets-operator"
  }
}

resource "aws_iam_policy" "eso" {
  name        = "${var.cluster_name}-eso-${var.team_name}"
  description = "ESO policy for ${var.team_name} scoped to team secret path"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.cluster_name}/${var.environment}/${var.team_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

# ── Pod Identity Association for ESO in this team namespace ───────────────────
resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace_v1.this.metadata[0].name
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eso.arn

  depends_on = [kubernetes_namespace_v1.this]
}

# ── App IAM role — no secrets access ─────────────────────────────────────────
resource "aws_iam_role" "app" {
  name               = "${var.cluster_name}-app-${var.team_name}"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = {
    Name        = "${var.cluster_name}-app-${var.team_name}"
    Team        = var.team_name
    Environment = var.environment
    Purpose     = "application-workload"
  }
}

resource "aws_iam_policy" "app" {
  count       = length(var.app_policy_statements) > 0 ? 1 : 0
  name        = "${var.cluster_name}-app-${var.team_name}"
  description = "App policy for ${var.team_name} workload"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.app_policy_statements
  })
}

resource "aws_iam_role_policy_attachment" "app" {
  count      = length(var.app_policy_statements) > 0 ? 1 : 0
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app[0].arn
}

# ── Pod Identity Association for app workload ─────────────────────────────────
resource "aws_eks_pod_identity_association" "app" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace_v1.this.metadata[0].name
  service_account = "${var.team_name}-sa"
  role_arn        = aws_iam_role.app.arn

  depends_on = [kubernetes_namespace_v1.this]
}

# ── Generate GitOps manifests ─────────────────────────────────────────────────
resource "local_file" "clustersecretstore" {
  content = templatefile("${path.module}/../../templates/gitops/clustersecretstore.yaml.tpl", {
    team_name    = var.team_name
    aws_region   = var.aws_region
    eso_role_arn = aws_iam_role.eso.arn
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/clustersecretstore.yaml"
}

resource "local_file" "externalsecret" {
  content = templatefile("${path.module}/../../templates/gitops/externalsecret.yaml.tpl", {
    team_name    = var.team_name
    cluster_name = var.cluster_name
    environment  = var.environment
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/externalsecret.yaml"
}

resource "local_file" "argocd_application" {
  content = templatefile("${path.module}/../../templates/gitops/argocd-application.yaml.tpl", {
    team_name   = var.team_name
    environment = var.environment
    repo_url    = var.repo_url
  })
  filename = "${path.module}/../../../gitops/clusters/${var.environment}/${var.team_name}-application.yaml"
}

resource "local_file" "namespace" {
  content = templatefile("${path.module}/../../templates/gitops/namespace.yaml.tpl", {
    team_name   = var.team_name
    environment = var.environment
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/namespace.yaml"
}

resource "local_file" "serviceaccount" {
  content = templatefile("${path.module}/../../templates/gitops/serviceaccount.yaml.tpl", {
    team_name = var.team_name
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/serviceaccount.yaml"
}

resource "local_file" "networkpolicy" {
  content = templatefile("${path.module}/../../templates/gitops/networkpolicy.yaml.tpl", {
    team_name = var.team_name
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/networkpolicy.yaml"
}

resource "local_file" "ingress" {
  content = templatefile("${path.module}/../../templates/gitops/ingress.yaml.tpl", {
    team_name     = var.team_name
    ingress_order = var.ingress_order
    domain_name   = var.domain_name
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/ingress.yaml"
}

resource "local_file" "deployment" {
  content = templatefile("${path.module}/../../templates/gitops/deployment.yaml.tpl", {
    team_name = var.team_name
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/deployment.yaml"
}

resource "local_file" "service" {
  content = templatefile("${path.module}/../../templates/gitops/service.yaml.tpl", {
    team_name = var.team_name
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/service.yaml"
}

resource "local_file" "resourcequota" {
  count = var.enable_resource_quota ? 1 : 0

  content = templatefile("${path.module}/../../templates/gitops/resourcequota.yaml.tpl", {
    team_name      = var.team_name
    cpu_requests   = var.resource_quota_cpu_requests
    cpu_limits     = var.resource_quota_cpu_limits
    memory_requests = var.resource_quota_memory_requests
    memory_limits  = var.resource_quota_memory_limits
    pods           = var.resource_quota_pods
  })
  filename = "${path.module}/../../../gitops/tenants/${var.environment}/${var.team_name}/resourcequota.yaml"
}
