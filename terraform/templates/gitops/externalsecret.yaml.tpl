apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: ${team_name}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: ${team_name}-secrets
    kind: ClusterSecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: ${cluster_name}/${environment}/${team_name}/db-credentials
        property: username
    - secretKey: password
      remoteRef:
        key: ${cluster_name}/${environment}/${team_name}/db-credentials
        property: password
