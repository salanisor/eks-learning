# ── IAM policy for the controller ────────────────────────────────────────────
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam-policy.json")
}

# ── IRSA role for the controller ──────────────────────────────────────────────
module "irsa" {
  source = "../irsa"

  cluster_name              = var.cluster_name
  oidc_provider_arn         = var.oidc_provider_arn
  oidc_provider_url         = var.oidc_provider_url
  role_name                 = "${var.cluster_name}-alb-controller"
  service_account_name      = "aws-load-balancer-controller"
  service_account_namespace = "kube-system"
  policy_arns               = [aws_iam_policy.alb_controller.arn]
}

# ── Helm release ──────────────────────────────────────────────────────────────
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.chart_version

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa.role_arn
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    }
  ]
}