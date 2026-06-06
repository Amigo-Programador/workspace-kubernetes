# ======================================================================================================================== #
# ====================================  INSTALAR VIRTUAL MACHINE [WORKER NODE] ==================================== #
# ======================================================================================================================== #

# Instala VMWare o algun otro virtualizador de tu preferencia
# Descarga una ISO de Linux Ubuntu
# Ingresa al virtualizador y crea una VM usando la ISO (Aun no instalar el S.O.)

# Apaga la VM y configurala para que tenga una IP static
# Opcional: En VMware editar el ethernet del VMnet0 > Establecer la misma ethernet que usa tu maquina local
Virtual network editor > VMnet0[Bridged] > Bridged to Realtek PCIe 2.5GbE Family Controller

# Configurar la VM para que tenga una IP static
Settings → Network Adapter → Bridged → Replicate physical network

# Valida una IP libre en tu red, usa el siguiente comando para ver las IPs usadas
 arp -a
# Tambien puede probar la conexion para validar el uso de un IP
 ping <ip-address> # Si no hay respuesta, esta IP esta libre

# Enciente la VM para instalar Linux Ubuntu
# En la parte de Network configuration ingresar una IPv4 Manualmente (para que sea estatica)

# ===================================================================================================== #
# ======================================  CONFIGURAR LA VM WORKER ====================================== #
# ===================================================================================================== #

# ---------------------------- RENAME MASTER NODE ----------------------------
$
# Cambia el nombre la virtual machine [localhost] > [master.amigo.programador]
hostnamectl set-hostname amigokloud-worker

# ---------------------------- RESOLUCION DNS ----------------------------

# cat <<EOF → inicia heredoc
# >> → agrega contendio al final del archivo | > → sobreescribe un archivo
# /etc/hosts → archivo que sirve para resolver [nombre de dominio/alias] > [dirrecion IP]
cat <<EOF >> /etc/hosts
192.168.18.130 amigokloud-master
192.168.18.131 amigokloud-worker
EOF

# ---------------------------- DISABLE FIREWALL ----------------------------
# Permite todo el trafico de red desde y hacia la VM
sudo ufw disable

# vim → abre un archivo en un editor de texto del terminal
# /etc/fstab → archivo que define los recursos de almacenamiento que Linux montara automaticamente al arrancar
# /swap.img → se comentara la linea para que el sistema no active swap incluso al reiniciar (usar # si no esta comentada)
vim /etc/fstab
/swap.img      none    swap    sw      0       0 #IMPORTANTE: comentar esta linea 

# ---------------------------- DISABLE MEMORY SWAP ----------------------------
# swapoff → desactiva memoria swap (memoria virtual del disco, kubernetes necesita memora RAM fisica)
#           [RAM virtual(ssd/disco)] degrada el rendimiento brutalmente | [RAM fisica(real)] kubernetes evita la inestibilidad e inconesistencia
# -a → desactiva todas las areas swap activas en el sistema Linux
swapoff -a

# ========================================================================================================= #
# ========================================  INSTALACION containerd ======================================== #
# ========================================================================================================= #

# ---------------------------- ENABLE OVERLAY ----------------------------

# sudo → ejecutar con permisos de administrador
# modprobe → herramienta para cargar modulos(drivers/controladores) en el kernel de Linux
# overlay → modulo OverlayFS (tecnologia de capas) 
#       [capa 1] Imagen base (inmutable, solo lectura) [.tar]
#       [capa 2] OverlayFS, copia de archivos de la imagen customizados, estos tienen prioridad sobre la imagen base
#       Kubernetes al levantar el POD inyecta los parametros en el proceso (este proceso usa como base los archivos de la imagen [capa 1, capa 2])
sudo modprobe overlay

# ---------------------------- ENABLE NETFILTER [Linux Kernel] ----------------------------
# br_netfilter → Permite conectar network interfaces fisicas [NODO] con network interfaces virtuales [POD]
sudo modprobe br_netfilter

# ---------------------------- NETWORK CONFIGURATION ----------------------------
# Flujo de peticiones desde INTERNET hasta el POD
# [Router IP] → IP publica, la decide tu proveedor de Internet (IPv4/IPv6).
# [NAT + Port Forwarding] → redirige el trafico hacia la IP de la VM
# [VM IP] → al instalar la VM, activamos el BRIDGE ADAPTER para que la VM reciba un IP fisica de tu propia red.
# [CNI plugin] → crea red virtual en cada NODO
#              → asigna una IP virtual a cada POD 
#              → conecta todos los PODs al BRIDGE del NODO mediante VethPairs
# [kube-proxy] → detecta los services y el puerto que esta escuchando
#              → crea reglas en "iptables" para redirigir el trafico que llega a un SERVICE → POD correspondiente
# [Service/INGRESS] → Expone al POD bajo un puerto y redirecciona el trafico
# [Pod Network Stack] → Interfaz de POD [eth0], cada POD tiene uno, es lo unico que ve. 
#                     → IP virtual, otorgada por CNI plugin.
#                     → Node Bridge, [cni0] todos los PODs del NODO se conectan a el mediante el VethPair
#                     → VethPair, conecta [eth0] del POD al BRIDGE del NODO [cni0]
#                     → Routing Table, actualizado por CNI plugin para que el POD pueda llegar a otros PODs dentro del segmento de red del NODO

# /etc/sysctl.d/*.conf → configuraciones persistentes [kernel]
# net.bridge.bridge-nf-call-ip6tables=1  → Permite que el trafico del BRIDGE pase por iptables
# net.bridge.bridge-nf-call-iptables=1   → Permite que el trafico del BRIDGE pase por iptables
# net.ipv4.ip_forward=1 → Permite al NODO Linux reenviar paquetes IP entre interfaces, necesario para Kubernetes y CNI plugins
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables=1 
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
EOF

# OJO → Puede que no se carge las configuraciones en sysctl, prueba ejecutando: 
sudo sysctl --system

# ---------------------------- AGREGAMOS REPOSITORIO docker ----------------------------

# [pre-requisitos] apt-transport-https→ Permite apt descargar paquetes usando HTTPS
# [pre-requisitos] ca-certificates→ verifica los certificados SSL de los sitios HTTPS
# curl gpg → Instala gpg, para manejar y verificar las llaves publicas que garantizan la autenticidad de los paquetes descargados.
# -y → aceptamos todas las preguntas de confirmacion
apt-get install apt-transport-https ca-certificates curl gpg -y

# mkdir → crea la la carpeta /keyrings
# -p → crea carpetas intermedias /etc/apt/keyrings
# -m 755 → asigna permisos 7(4+2+1)=root, 5(4+0+1)=group, 5(4+0+1)=others | 4=lectura, 2=escritura, 1=ejecucion
# /etc/apt/keyrings → ruta para almacenar llaves publicas GPG (llave de Docker, Kubernetes...) < apt lo usa para cerciorarse que las descargar no hayan sido alteradas
mkdir -p -m 755 /etc/apt/keyrings

# curl → descarga datos de una url
# -f → si hay un error, no muestra un HMTL, sino el codigo del error
# -s → no muestra la barra de progreso
# -S → muestra el mensaje de error si algo falla
# -L → sigue las redirecciones HTTP si la url lo requiere
# https://download.docker.com/linux/ubuntu/gpg : URL donde Docker publica su llave publica GPG, valida que el Docker que descarguemos sea el oficial tal y como lo publicaron. (Sin esta llave nos saldria un error 'The following signatures couldn't be verified because the public key is not available')
# -o /etc/apt/keyrings/docker.asc : guarda lo descargado en esa ruta                                                                                                 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# chmod → cambia permisos de un archivo
# a → all (aplica a todos los usuarios root|group|others)
# +r → les añade permiso de lectura
# /etc/apt/keyrings/docker.asc → archivo donde guardamos la llave publica de docker, le daremos acceso de lectura a este.
chmod a+r /etc/apt/keyrings/docker.asc

# echo → imprime en la terminal lo que le pases de parametro
#   "deb → indica que es un repo de archivos binarios .deb
#    [arch=$(dpkg --print-architecture) → tipo de arquitectura usa la instalacion Debian/Ubunto de la VM
#    signed-by=/etc/apt/keyrings/docker.asc] → verifica las descargas usando la llave GPG docker.asc
#    https://download.docker.com/linux/ubuntu → url del repositorio
#    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" → extrae el valor VERSION_CODENAME del archivo os-release y lo concatena con stable | jammy stable (distribuidos para jammy en la sección stable)
# sudo tee /etc/apt/sources.list.d/docker.list → Guarda la direccion del repositorio, es leido por apt luego (no ha descargado nada aun)
# > /dev/null → impide imprimir el texto de echo en pantalla
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# ---------------------------- INSTALL containerd ----------------------------

# apt-get → herramienta de gestion de paquestes debian, ubuntu
# update → se conecta al repositorio usando los archivos /etc/apt/sources.list.d/*.list y descarga la metada actualizada
apt-get update

# apt-get → herramienta de gestion de paquestes debian, ubuntu
# install → instala paquetes
# containerd.io → nombre del paquete, contiene archivos binarios .deb, permite usar containerd como comando
# -y → acepta automaticamente todas las confirmaciones
apt-get install containerd.io -y


# ---------------------------- CONFIGURE containerd ----------------------------

# containerd → comando instalado en /usr/bin/containerd
# config default → genera un archivo de configuracion por defecto de containerd (no importa si actualizaste alguna configuracion)
# sudo tee /etc/containerd/config.toml → escribe la salida anterior en un archivo config.toml
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null


# ---------------------------- MODIFY config.toml  ----------------------------
# vim → modificamos el archivo de configuracion por defecto
vim /etc/containerd/config.toml

# [plugins."io.containerd.grpc.v1.cri".containerd]
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
snapshotter = "overlayfs"

# [plugins.'io.containerd.cri.v1.runtime'.containerd]
# [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
SystemdCgroup = true

# ---------------------------- START containerd ----------------------------
# systemctl → sistema gestion de servicios de inicializacion
# enable → enlaza un programa al arranque del sistema (boot)
# --now containerd → inicia ahora el programa
systemctl enable --now  containerd

# systemctl status → muestra el estado actual del servicio
systemctl status containerd

# =================================================================================================================== #
# ====================================  INSTALACION KUBERNETES [Todos los nodos] ==================================== #
# =================================================================================================================== #

# ---------------------------- LLAVE PUBLICA ----------------------------
# curl -fsSL → descarga datos de una url
# https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key → Ubicacion de la llave publica del repositorio de kubernetes [.key]
# sudo gpg → GNU Privacy Guard (maneja claves de cifrado)
# --dearmor → convierte la clave a formato [.gpg]
# -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg → el resultado (llave publica) se guarda en esa ruta
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# ---------------------------- REGISTRAMOS REPOSITORIO DE KUBERNETES ----------------------------
# echo → imprime en pantalla un texto
# deb → indica que lo que sigue es un repositorio apt
# signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg → indica la ruta de la llave publica
# https://pkgs.k8s.io/core:/stable:/v1.30/deb/ → URL del repositorio
# / → distribucion Linux (jammy, focal, bookworm) [en esta caso distribucion generica]
# sudo tee /etc/apt/sources.list.d/kubernetes.list → copia rutas del repositorio de Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# ---------------------------- DESCARGAMOS METADATA DEL REPOSITORIO ----------------------------
# apt-get update → Linux revisa /etc/apt/sources.list/* y descarga la metadata
# La metadata se guarda en paquetes como /var/lib/apt/lists/pkgs.k8s.io_core:_stable:_v1.30_deb_Packages
apt-get update

# ---------------------------- INSTALAR BINARIOS DE KUBERNETES ----------------------------
# apt-get install → cheka la metadata descargada /var/lib/apt/lists/pkgs.k8s.io_core:_stable:_v1.30_deb_Packages [Aqui se encuentra _Packages como kubelet, kubeadm, kubectl...]
# -y → yes automatico a las confirmaciones
# kubelet kubeadm kubectl → paquetes descargados(metadata) en kubernetes.list
apt-get install -y kubelet kubeadm kubectl

# ---------------------------- CONGELAR PAQUETES INSTALADOS (servicios, programas, cli) ----------------------------
# apt-mark hold → marca un paquete como retenido, congela la version para no actualizarse automaticamente
# kubelet kubeadm kubectl → el cluste kubenertes debe mantenerse sincronizo, sino podria romper la compatibilidad 
apt-mark hold kubelet kubeadm kubectl

# ---------------------------- INICIALIZAMOS kubelet AUTOMATICAMENTE EN CADA ARRANQUE ----------------------------
# [symlink] /etc/systemd/system/multi-user.target.wants/kubelet.service → ruta Linux donde definen programas de arranque
# [Archivo configuracion] /lib/systemd/system/kubelet.service → ruta por defecto al instalar kubelet
# [Ejecutable real] ExecStart=/usr/bin/kubelet → archivo binario
systemctl enable --now kubelet

# ============================================================================================== #
# ====================================  INSTALL WORKER NODE ==================================== #
# ============================================================================================== #

# ---------------------------- JOIN WITH MASTER NODE ----------------------------
# Comando que aparecio al finalizar la instalacion del master node
kubeadm join 192.168.18.130:6443 --token i76074.a5ck4k6bgz7s2ib8 \
        --discovery-token-ca-cert-hash sha256:be9435d31c88b97796018937bda9ac34cb527ad279b638e40957b59e4bb74a28

NOTA: Si existe algun error al hacer kubeadm join
# Valida el swap con este comando, debe salir → Swap 0B
free -h 

# Valida los comandos bridge, forward esten como 1
sysctl --system
# debe mostrar asi
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1

# Reinicia containerD
systemctl restart containerd

# Resetea el intento de kubeadm join
kubeadm reset -f

# Si perdiste el token, vuelve a generarlo en el nodo master
kubeadm token create --print-join-command