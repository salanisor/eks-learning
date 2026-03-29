kubectl port-forward -n argocd \
  $(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name) \
  9090:80
