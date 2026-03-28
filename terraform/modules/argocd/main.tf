# ── ArgoCD namespace ──────────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      managed-by = "terraform"
    }
  }
}

# ── ArgoCD Helm release ───────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = var.chart_version

  set = [
    {
      name  = "global.domain"
      value = "argocd.${var.cluster_name}.internal"
    },
    {
      name  = "configs.params.server\\.insecure"
      value = "true"
    },
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]

  depends_on = [kubernetes_namespace_v1.argocd]
}

# ── ArgoCD IAM role for Pod Identity ─────────────────────────────────────────
data "aws_iam_policy_document" "argocd_trust" {
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

resource "aws_iam_role" "argocd" {
  name               = "${var.cluster_name}-argocd"
  assume_role_policy = data.aws_iam_policy_document.argocd_trust.json

  tags = {
    Name    = "${var.cluster_name}-argocd"
    Purpose = "argocd-gitops"
  }
}

# ── Pod Identity Association for ArgoCD ───────────────────────────────────────
resource "aws_eks_pod_identity_association" "argocd" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace_v1.argocd.metadata[0].name
  service_account = "argocd-application-controller"
  role_arn        = aws_iam_role.argocd.arn

  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.argocd
  ]
}
