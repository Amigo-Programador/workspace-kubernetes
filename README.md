# Question 10 | RBAC ServiceAccount Role RoleBinding

## 1. Create a new ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: processor-sa
  namespace: moon
```


## 2. Create a Role and RoleBinding

Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: processor-role
  namespace: moon
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  - configmaps
  verbs:
  - create
```

RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: processor
  namespace: moon
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: processor-role
subjects:
- kind: ServiceAccount
  name: processor-sa
  namespace: moon
```

## 3. RoleBinding allow Service Account allow do role permition actions

Permiso → create
Que recursos → secrets, configmaps 
el Namespace depende del Binding