apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: ${team_name}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-alb-ingress
  namespace: ${team_name}
spec:
  podSelector:
    matchLabels:
      app: ${team_name}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - ipBlock:
            cidr: 10.0.0.0/16
      ports:
        - protocol: TCP
          port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: ${team_name}
spec:
  podSelector:
    matchLabels:
      app: ${team_name}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-pod-identity-egress
  namespace: ${team_name}
spec:
  podSelector:
    matchLabels:
      app: ${team_name}
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 169.254.170.23/32
      ports:
        - protocol: TCP
          port: 80
