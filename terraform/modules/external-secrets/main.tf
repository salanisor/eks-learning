data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "eso_trust" {
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

resource "aws_iam_role" "eso" {
  name               = "${var.cluster_name}-eso"
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json

  tags = {
    Name    = "${var.cluster_name}-eso"
    Purpose = "external-secrets-operator"
  }
}

resource "aws_iam_policy" "eso_assume" {
  name        = "${var.cluster_name}-eso-assume-roles"
  description = "Allows ESO to assume per-team scoped roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeTeamRoles"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-eso-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_assume" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso_assume.arn
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = var.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eso.arn
}
