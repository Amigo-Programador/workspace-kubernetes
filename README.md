# Ingress - Service - Deployment

## 1. Create Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
  namespace: sound
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - image: gcr.io/google_containers/echoserver:1.10
        imagePullPolicy: IfNotPresent
        name: echo
        ports:
        - containerPort: 8080
          protocol: TCP
```

## 2. Expose Deployment with Service
```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  name: echo-service
  namespace: sound
spec:
  type: NodePort
  selector:
    app: echo
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
```

## 3. Create Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: sound
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: amigo.programador.org
      http:
        paths:
          - path: /echo-path
            pathType: Prefix
            backend:
              service:
                name: echo-service
                port:
                  number: 8080
```
