apiVersion: v1
kind: Namespace
metadata:
  name: ${team_name}
  labels:
    team: ${team_name}
    environment: ${environment}
    managed-by: argocd
