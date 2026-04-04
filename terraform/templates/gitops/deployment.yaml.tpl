apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${team_name}
  namespace: ${team_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${team_name}
  template:
    metadata:
      labels:
        app: ${team_name}
    spec:
      serviceAccountName: ${team_name}-sa
      containers:
        - name: ${team_name}
          image: public.ecr.aws/docker/library/nginx:alpine
          ports:
            - containerPort: 80
          env:
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
