KUBERNETES

# Problema con Calico
## Log del pod al intentar crearlo
### Calico intenta consultar al API Server para obtener ClusterInformation, pero no tiene autorizacion
Warning  FailedCreatePodSandBox  8s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "deeade4d75ecb635d10754973b454409b0d393330b75d4bddc28f576c0059f71": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorized
  Normal   SandboxChanged          4s (x12 over 15s)  kubelet            Pod sandbox changed, it will be killed and re-created.
  Warning  FailedCreatePodSandBox  4s (x4 over 7s)    kubelet            (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "d4a4d41d8af55491f5e2e4f57916bb9f2e66d81cfb92799fac7919c93af43555": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorized


## Si no tienes acceso, porque falta permites de lectura al kubelet.conf
kubelet.conf > Permite el acceso de al API Server

Ejecutar:
sudo chmod 644 /etc/kubernetes/kubelet.conf

## OJO! 
### Al hacer esto en el Worker Node
kubelet puede estar negándose a usar kubelet.conf por terner permisos demasiado abiertos
Kubernetes ES ESTRICTO con los permisos de credenciales sensibles, entonces lo RECHAZA por seguridad.

### Solucion: darle a  kubelet.conf permisos de lectura solamente al usuario root
sudo chmod 600 /etc/kubernetes/kubelet.conf  
### Deberia quedar asi
-rw------- 1 root root kubelet.conf

### Luego reinicia kubelet
sudo systemctl restart kubelet

### Elimina el pod Calico, para que Kubernetes lo recree automaticamente
kubectl get pods -n kube-system -o wide | grep worker1
kubectl delete pod -n kube-system <nombre-del-calico-node>


## OTRA COSA QUE VALIDAR!!
### Que el servidor NFS este correctamente configurado, en caso haya cambiado de IP, se debe actualizar la IP
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: nfs-client-provisioner
  name: nfs-client-provisioner
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-cna
              mountPath: /persistentvolumes #El esta carpeta monta el contenido del NFS
          env:
            - name: PROVISIONER_NAME
              value: nfs-provisioner
            - name: NFS_SERVER
              value: 192.168.18.126   	#ACTUALIZAR DE SER NECESARIO
            - name: NFS_PATH
              value: /srv/nfs/k8s  	#Carpeta exportada dentro del NFS (data persistente)
      volumes:
        - name: nfs-client-cna
          nfs:
            server: 192.168.18.126    	#ACTUALIZAR DE SER NECESARIO
            path: /srv/nfs/k8s   	#Carpeta exportada del NFS


### Luego eliminar el pod manualmente y esperar que el deployment vuelva a crearlo, esta vez con la IP correcta del servidor NFS            