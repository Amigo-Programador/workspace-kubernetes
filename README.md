# Deployment - Service - NodePort

## 1. Create Deployment 
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodeport-deployment
  namespace: relative
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nodeport-deployment
  template:
    metadata:
      labels:
        app: nodeport-deployment
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - name: http
          protocol: TCP
          containerPort: 80
```

## 2. Create Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: relative
spec:
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30080
  selector:
    app: nodeport-deployment
```
