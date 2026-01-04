# PV - PVC - DATABASE MariaDB

## 1. Create Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpass
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: mariadb


## 2. Create Persistence Volume
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 250Mi
  hostPath:
    path: /mnt/data/mariadb


## 3. Create Persistent Volume Claim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi