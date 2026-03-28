locals {
  admin_users = [
    for arn in var.admin_iam_arns : {
      userarn  = arn
      username = split("/", arn)[length(split("/", arn)) - 1]
      groups   = ["system:masters"]
    }
  ]

  readonly_users = [
    for arn in var.readonly_iam_arns : {
      userarn  = arn
      username = split("/", arn)[length(split("/", arn)) - 1]
      groups   = ["developer-readonly"]
    }
  ]
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  force = true

  data = {
    mapRoles = yamlencode(concat(
      [
        {
          rolearn  = var.node_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }
      ],
    ))

    mapUsers = yamlencode(concat(
      local.admin_users,
      local.readonly_users
    ))
  }
}