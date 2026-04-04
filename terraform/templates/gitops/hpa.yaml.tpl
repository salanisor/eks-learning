apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${team_name}
  namespace: ${team_name}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${team_name}
  minReplicas: ${min_replicas}
  maxReplicas: ${max_replicas}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: ${cpu_target}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: ${memory_target}
