apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: ${team_name}-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${aws_region}
      role: ${eso_role_arn}
