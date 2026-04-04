apiVersion: v1
kind: Service
metadata:
  name: ${team_name}
  namespace: ${team_name}
spec:
  selector:
    app: ${team_name}
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
