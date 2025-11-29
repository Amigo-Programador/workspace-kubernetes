# Question 6 | Storage, PV, PVC, Pod volume

### 1. Create a new PersistentVolume named safari-pv. 
It should have a capacity of 2Gi, accessMode ReadWriteOnce, hostPath /Volumes/Data and no storageClassName defined.

### 2. Next create a new PersistentVolumeClaim in Namespace project-tiger named safari-pvc. 
It should request 2Gi storage, accessMode ReadWriteOnce and should not define a storageClassName. The PVC should bound to the PV correctly.

### 3. Finally create a new Deployment safari in Namespace project-tiger. 
Which mounts that volume at /tmp/safari-data. 
The Pods of that Deployment should be of image httpd:2.4.41-alpine.

### PersistentVolume: safari-pv

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: safari-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Volumes/Data"
```    

### PersistentVolumeClaim: safari-pvc

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: safari-pvc
  namespace: project-tiger
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
     storage: 2Gi
```     

### Deployment: safari

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: safari
  namespace: project-tiger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: safari
  template:
    metadata:
      labels:
        app: safari
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: safari-pvc
      containers:
      - image: httpd:2.4.41-alpine
        name: container
        volumeMounts:
        - name: data
          mountPath: /tmp/safari-data
```

