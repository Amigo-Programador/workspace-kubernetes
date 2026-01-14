# Gateway API - Ingress

## 1. Instala CRDs de Gateway API, RBAC, Políticas y validaciones
```yaml
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```

## 2. Instala CRDs propias del controlador NGINX Gateway Fabric
```yaml
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.2/deploy/crds.yaml
```

## 3. Instala el controlador NGINX Gateway Fabric [namespace, service account, RBAC, deployment]
```yaml
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.2/deploy/default/deploy.yaml
```
Luego valida el Pod Gateway Fabric Controller que se ha creado
```yaml
kubectl get pods -n nginx-gateway
```


## 4. Crea un TLS certificate  
```yaml
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=amigo.programador/O=example" -addext "subjectAltName=DNS:amigo.programador"
```

## 5. Crea  un secret: [tls.crt → el certificado y tls.key → la clave privada]
```yaml
kubectl create secret tls tls-certificado --cert=tls.crt --key=tls.key
```

## 6. Crea un deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: nginx
        name: web
        ports:
        - containerPort: 80
          protocol: TCP
```

## 7. Crea un service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  type: ClusterIP
```

## 8. create Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - amigo.programador
    secretName: tls-certificado
  rules:
  - host: amigo.programador
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

## 9. Crear el Gateway
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: amigo.programador
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: tls-certificado
```

## 10. Crear el HTTPRoute
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "amigo.programador"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
```