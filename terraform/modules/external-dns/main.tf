# ── ExternalDNS namespace ─────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
    labels = {
      managed-by = "terraform"
    }
  }
}

# ── ExternalDNS Helm release ──────────────────────────────────────────────────
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = kubernetes_namespace_v1.external_dns.metadata[0].name
  version    = var.chart_version

  set = [
    {
      name  = "provider.name"
      value = "aws"
    },
    {
      name  = "env[0].name"
      value = "AWS_DEFAULT_REGION"
    },
    {
      name  = "env[0].value"
      value = var.aws_region
    },
    {
      name  = "domainFilters[0]"
      value = var.domain_filter
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-dns"
    },
    {
      name  = "policy"
      value = "sync"
    }
  ]

  depends_on = [kubernetes_namespace_v1.external_dns]
}

# ── ExternalDNS IAM role for Pod Identity ─────────────────────────────────────
data "aws_iam_policy_document" "external_dns_trust" {
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

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust.json

  tags = {
    Name    = "${var.cluster_name}-external-dns"
    Purpose = "external-dns-route53"
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "${var.cluster_name}-external-dns"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns.json
}

# ── Pod Identity Association for ExternalDNS ──────────────────────────────────
resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace_v1.external_dns.metadata[0].name
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn

  depends_on = [
    kubernetes_namespace_v1.external_dns,
    helm_release.external_dns
  ]
}
