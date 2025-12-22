# Question 15 | Cluster Event Logging

## 1. Mostrar los ultimos eventos del cluster

```yaml
kubectl get events -A --sort-by=.metadata.creationTimestamp
```



## 2. Kill kube-proxy on worker node

```yaml
k get pods -n kube-system | grep proxy
```
Obtienes un kube-proxy por cada nodo
```yaml
master@master:~$ k get pods -n kube-system -o wide | grep proxy
kube-proxy-684jc    1/1     Running   19 (8m2s ago)    77d     192.168.18.120   master.amigo.programador
kube-proxy-bgx65    1/1     Running   1 (7m56s ago)    2d3h    192.168.18.121   worker1.amigo.programador
```

Borrar el pod de kube-proxy manualmente
```yaml
kubectl delete pod kube-proxy-bgx65 -n kube-system
```

Vemos los eventos y lo guardamos en un archivo
```yaml
kubectl delete pod kube-proxy-bgx65 -n kube-system
```
```yaml
kube-system     74s         Normal    Scheduled                 pod/kube-proxy-6d2vz                                   Successfully assigned kube-system/kube-proxy-6d2vz to worker1.amigo.programador
kube-system     75s         Normal    SuccessfulCreate          daemonset/kube-proxy                                   Created pod: kube-proxy-6d2vz
kube-system     75s         Normal    Killing                   pod/kube-proxy-bgx65                                   Stopping container kube-proxy
kube-system     74s         Normal    Created                   pod/kube-proxy-6d2vz                                   Created container: kube-proxy
kube-system     74s         Normal    Pulled                    pod/kube-proxy-6d2vz                                   Container image "registry.k8s.io/kube-proxy:v1.30.14" already present on machine
default         74s         Normal    Starting                  node/worker1.amigo.programador
kube-system     74s         Normal    Started                   pod/kube-proxy-6d2vz                                   Started container kube-proxy
```

## 3. Kill containerD of the kube-proxy Pod on worker node
Encontrar el container de kube-proxy
```yaml
crictl ps | grep proxy
```

Borrar el pod de kube-proxy manualmente
```yaml
#Primero
crictl stop 526464646
crictl rm 526464646
```

Validar los logs de eventos nuevos
```yaml
kube-system     28s         Normal    Pulled                    pod/kube-proxy-6d2vz                                   Container image "registry.k8s.io/kube-proxy:v1.30.14" already present on machine
kube-system     28s         Normal    Created                   pod/kube-proxy-6d2vz                                   Created container: kube-proxy
kube-system     28s         Normal    Started                   pod/kube-proxy-6d2vz                                   Started container kube-proxy
default         5m22s       Normal    Starting                  node/master.amigo.programador
default         27s         Normal    Starting                  node/worker1.amigo.programador
```