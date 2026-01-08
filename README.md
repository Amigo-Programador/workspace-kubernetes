# Gateway API - Ingress

## 1. installing the Gateway API CRDs from the official repo

kubectl kustomize "https://github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" | kubectl apply -f -

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml


## 2. Install NGINX Gateway Controller

kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.2/deploy/crds.yaml

kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.2/deploy/default/deploy.yaml

kubectl get pods -n nginx-gateway



## 3. create a TLS certificate

openssl req -x509 -nodes -days 365 -newkey rsa:2048   -keyout tls.key -out tls.crt -subj "/CN=api.zenhost.local/O=zenhost"


## 4. create the secret:

kubectl create secret tls zenhost-cert --cert=tls.crt --key=tls.key

## 5. create Ingress from yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.zenhost.local
    secretName: zenhost-cert
  rules:
  - host: api.zenhost.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo-service
            port:
              number: 80

## 5. create Gateway from yaml

apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx-class
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: gateway.web.k8s.local
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls

## 5. create HTTPRoute from yaml

apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "gateway.web.k8s.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
