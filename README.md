# Preview Question 3

## 1. Create a Pod named check-ip
```yaml
kubectl run check-ip --image httpd:2.4.41-alpine
```

## 2. Expones Pod check-ip with a Service named check-ip-service
Crea el service
```yaml
kubectl expose pod check-ip --name check-ip-service --port 80
```

Valida que el kube-apiservice creo el service
```yaml
kubectl get services

master@master:~$ kubectl get services
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
check-ip-service     ClusterIP   10.100.184.134   <none>        80/TCP    35h
```


Revisa el endpoint creado por el kube-controller-manager
```yaml
kubectl get ep

master@master:~$ kubectl get ep
NAME                 ENDPOINTS             AGE
check-ip-service     172.16.195.140:80     35h
```

## 3. Cambia el service CIDR
Dirigete al Master Node, entra como usuario root, valida el yaml del kube-apiserver, con el comando
```yaml
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

Actualiza el parametro que define el rango de IPs para el service CIDR
```yaml
   --service-cluster-ip-range=10.96.0.0/12

# En unos momentos el kube-apiserver se reiniciara con el parametro actualizado
```

Actualiza el mismo parametro en el kube-controller-manager
```yaml
vim /etc/kubernetes/manifests/kube-controller-manager.yaml

# En unos momentos el kube-controller-manager se reiniciara con el parametro actualizado
```

