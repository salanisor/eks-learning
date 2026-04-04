apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${team_name}
  namespace: argocd
spec:
  project: dev-tenants
  source:
    repoURL: ${repo_url}
    targetRevision: main
    path: gitops/tenants/${environment}/${team_name}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${team_name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
      - RespectIgnoreDifferences=true
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /status/terminatingReplicas
    - group: external-secrets.io
      kind: ExternalSecret
      jsonPointers:
        - /spec/data
