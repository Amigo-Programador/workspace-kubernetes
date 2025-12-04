KUBERNETES

# Problema con Calico

### El POD NFS no puede terminar de crearse
nfs-client-provisioner-cdd74758b-pcq98   0/1     ContainerCreating   0              23h

### Calico intenta consultar al API Server para obtener ClusterInformation, pero no tiene autorizacion
Warning  FailedCreatePodSandBox  42s (x1573 over 23h)  kubelet            (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "e1ae60874da1030ec7cd39bc1d0ca11f474f5ccb5be6aba5e2f0fd633bce86da": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorized

### El worker node tiene acceso al API Server?
#### 1. Validar los permisos, archivo kubelet.conf > Permite el acceso de al API Server
Por ejemplo si el archivo tiene los permisos 644:
sudo chmod 644 /etc/kubernetes/kubelet.conf

kubelet puede estar negándose a usar kubelet.conf por terner permisos demasiado abiertos
Kubernetes ES ESTRICTO con los permisos de credenciales sensibles, entonces lo RECHAZA por seguridad.

#### 2. Darle a  kubelet.conf permisos de lectura solamente al usuario root
sudo chmod 600 /etc/kubernetes/kubelet.conf  

Para que solo el root tenga acceso y kubernetes no daria error.
-rw------- 1 root root kubelet.conf

#### 3. Luego reinicia kubelet
sudo systemctl restart kubelet

#### 4. Validar conexion del worker node hacien el API Server (MASTER NODE)
curl -k https://192.168.18.120:6443/version

Deberia dar la informacion basica del API Server (Significa que si hay conexion)
{
  "major": "1",
  "minor": "30",
  "gitVersion": "v1.30.14",
  "gitCommit": "9e18483918821121abdf9aa82bc14d66df5d68cd",
  "gitTreeState": "clean",
  "buildDate": "2025-06-17T18:29:20Z",
  "goVersion": "go1.23.10",
  "compiler": "gc",
  "platform": "linux/amd64"
}

### En POD NFS no llega 1/1 Running?

#### Valida que la IP de la VM NFS sea el mismo que el deployment NFS 
nfs-deployment
- name: NFS_SERVER
  value: 192.168.18.122

nfs server (ip addr)
192.168.18.126  #La ip a cambiado


####  Elimina el pod NFS
kubectl delete deployment nfs
kubectl delete pod nfs-123 --force

#### Crear denuevo el manifest del deploymen, con la IP correcta
vim  nfs-deployment.yaml
```yaml
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
```

####  Cree el deployment
kubectl -f apply nfs-deployment.yaml