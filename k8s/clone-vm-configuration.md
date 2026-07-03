# Configurar VM Clonada
## 1. Cambiar nombre de la VM
```bash
hostnamectl set-hostname amigoprogramador-master
```
## 2.1. Crear un archivo de configuración de red de Ubuntu
```bash
vim /etc/netplan/00-installer-config.yaml
```
## 2.2. Cambiar la IP de DHCP a Estática
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.18.150/24
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
      routes:
        - to: default
          via: 192.168.18.1
```          
## 2.2. Actualizar permisos de edicion del archivo
```bash
chmod 600 /etc/netplan/00-installer-config.yaml
```
## 2.3. Aplicamos la configuracion
```bash
netplan apply
```
## 3.1. Limpiar archivo machine-id
```bash
truncate -s 0 /etc/machine-id
```
## 3.2. Forzar la eliminación del archivo machine-id que quedó vacío
```bash
rm -f /etc/machine-id /var/lib/dbus/machine-id
```
## 3.3. Generar limpiamente un nuevo machine-id
```bash
systemd-machine-id-setup
```
## 3.4. Verifica el nuevo ID en el archivo machine-id
```bash
cat /etc/machine-id
```
## 4. Reiniciar la VM
```bash
sudo reboot
```