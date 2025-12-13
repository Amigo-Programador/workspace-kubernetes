# Question 9 | Kill Scheduler, Manual Scheduling

## 1. Temporarily stop the kube-scheduler
En el nodo master, ir a la ruta 
```yaml
cd /etc/kubernetes/manifests/
```

Luego mover el yaml manifest del scheduler
```yaml
mv kube-scheduler.yaml ..
```

kubelet monitorea esta carpeta, y removera el scheduler si retiramos el yaml.

## 2. Create a single Pod
Creamos el siguiente pod
```yaml
kubectl run manual-schedule --image=httpd:2.4-alpine
```

Como no hay scheduler que asigne pods a un nodo, quedara en estado Pending
```yaml
NAME              READY   STATUS    ...   NODE     NOMINATED NODE
manual-schedule   0/1     Pending   ...   <none>   <none>
```

## 3. Manually schedule the Pod
Agregamos esta linea en el yaml manifest del POD
```yaml
spec:
  nodeName: master.amigo.programador        # master node
  containers:
```

Ahora forzamos a que pod se cree en el nodo especificado (las validaciones de tolerations/taints/affinity no se validan en esta forma)
```yaml
root@master:~# k get pods | grep manual
manual-schedule                           1/1     Running   1 (23m ago)    13h
```

## 4. Start the scheduler again
En el nodo master, ir a la ruta 
```yaml
cd /etc/kubernetes/manifests/
```

Regresar el manifest del scheduler
```yaml
mv ../kube-scheduler.yaml .
```

kubelect creara denuevo el scheduler y los pod seran asignados automaticamente a sus nodos.