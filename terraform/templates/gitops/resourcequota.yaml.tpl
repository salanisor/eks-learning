apiVersion: v1
kind: ResourceQuota
metadata:
  name: ${team_name}-quota
  namespace: ${team_name}
spec:
  hard:
    requests.cpu: "${cpu_requests}"
    limits.cpu: "${cpu_limits}"
    requests.memory: "${memory_requests}"
    limits.memory: "${memory_limits}"
    pods: "${pods}"
