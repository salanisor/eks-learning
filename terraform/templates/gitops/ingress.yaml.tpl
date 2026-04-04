apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${team_name}
  namespace: ${team_name}
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: eks-learning-shared
    alb.ingress.kubernetes.io/group.order: "${ingress_order}"
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    external-dns.alpha.kubernetes.io/hostname: ${team_name}.${domain_name}
spec:
  ingressClassName: alb
  rules:
    - host: ${team_name}.${domain_name}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${team_name}
                port:
                  number: 80
