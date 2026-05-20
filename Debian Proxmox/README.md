# Instalación de Proxmox VE 8.4 en Debian 12 (Bookworm)

Este README proporciona los pasos necesarios para realizar una instalación de Proxmox VE 8.4 sobre una instalación mínima de Debian 12 "Bookworm". Esta guía se enfoca en asegurar una configuración de red y `hostname` correcta, que son puntos críticos para el funcionamiento de Proxmox.

---

## 📋 Prerrequisitos

*   Una instalación limpia y mínima de Debian 12 (Bookworm) con acceso a la línea de comandos (`root` o `sudo`).
*   Conexión a Internet activa en la máquina Debian.
*   **¡Importante para VMs!** Si estás instalando Proxmox VE dentro de una Máquina Virtual (por ejemplo, en VirtualBox, VMware, etc.), asegúrate de que la **virtualización anidada (Nested Virtualization)** esté habilitada en la configuración del hipervisor subyacente de la VM. Sin esto, Proxmox no funcionará correctamente.
    *   **En VirtualBox:** Ve a la configuración de la VM Proxmox > Sistema > Procesador > Marca "Habilitar VT-x/AMD-V Anidado" (Enable Nested VT-x/AMD-V).
*   **Hardware:**
    *   CPU x86_64 con soporte de virtualización (Intel VT-x/EPT o AMD-V/RVI).
    *   Al menos 4 GB de RAM (8 GB o más recomendado).
    *   Un disco duro con al menos 32 GB de espacio libre (SSD recomendado).
    *   Una o más tarjetas de red (NICs).

---

## 🛠️ Pasos de Instalación

### Paso 1: Actualizar el Sistema Debian

Asegúrate de que tu instalación de Debian esté completamente actualizada antes de comenzar.

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install curl wget gnupg2 software-properties-common -y
```

### Paso 2: Configuración Inicial de Red y Hostname

Esta es la parte MÁS CRÍTICA. Proxmox VE requiere un FQDN (Fully Qualified Domain Name) correcto y una dirección IP estática que se resuelva correctamente.

#### 2.1 Configurar una IP Estática (Recomendado)

Es altamente recomendado que tu nodo Proxmox tenga una IP estática. Modifica el archivo `/etc/network/interfaces`.

```bash
sudo nano /etc/network/interfaces
```

**Ejemplo para una interfaz `vmbr0` (bridge) sobre `enp0s3`:**

```
auto lo
iface lo inet loopback

# Configuración de tu interfaz física
# Reemplaza 'enp0s3' con el nombre de tu interfaz física real (ej. eth0, eno1, enp4s0)
# Puedes ver tus interfaces con 'ip a'

# Configura el bridge virtual para Proxmox
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.10/24   # <<--- TU IP ESTATICA y Máscara de Subred (ej. 192.168.1.10/24)
    gateway 192.168.1.1       # <<--- TU GATEWAY (ej. 192.168.1.1)
    bridge-ports enp0s3       # <<--- TU INTERFAZ FÍSICA (ej. enp0s3)
    bridge-stp off
    bridge-fd 0
    dns-nameservers 8.8.8.8 8.8.4.4 # <<--- Tus servidores DNS preferidos (ej. los de Google)
    # dns-search localdomain    # Opcional: tu dominio local, si tienes uno
```

Guarda los cambios (`CTRL + O`, `Enter`, `CTRL + X`).

Aplica los cambios de red:

```bash
sudo systemctl restart networking
# O, si tienes problemas, un reinicio completo del sistema:
# sudo reboot
```

Verifica tu configuración IP:

```bash
ip a
```
Asegúrate de que la IP configurada se haya aplicado a `vmbr0`.

#### 2.2 Configurar Hostname y `/etc/hosts`

Proxmox necesita que el nombre de host del nodo se resuelva a una dirección IP real (no de loopback) en `/etc/hosts`.

1.  **Editar `/etc/hostname`**:
    Abre el archivo y asegúrate de que contenga solo el nombre corto de tu servidor (ej. `pve`).

    ```bash
    sudo nano /etc/hostname
    ```
    Contenido del archivo (ejemplo):
    ```
    pve
    ```
    Guarda y cierra.

2.  **Editar `/etc/hosts`**:
    Este paso es CRÍTICO para evitar errores como `Unable to resolve node name '...' to a non-loopback IP address`.

    ```bash
    sudo nano /etc/hosts
    ```
    Asegúrate de que el archivo se vea similar a esto (reemplaza `TU_IP_PROXMOX` con la IP estática que configuraste, y `pve.midominio.local` con tu FQDN deseado o `pve.localdomain` si no tienes uno específico):

    ```
    127.0.0.1       localhost
    TU_IP_PROXMOX   pve.midominio.local pve
    # 127.0.1.1     pve  # <<--- COMENTA O ELIMINA ESTA LÍNEA SI EXISTE
    ```
    **Explicación:** La línea `127.0.1.1` que Debian suele añadir por defecto para el hostname debe ser **comentada o eliminada** cuando se añade la línea con tu IP real. `pmxcfs` se queja de "non-loopback IP address" precisamente por esto.

    Guarda y cierra.

3.  **Verificar el FQDN**:
    Después de los cambios, es vital que tu sistema resuelva el FQDN correctamente.
    ```bash
    hostname --fqdn
    ```
    Esto debería devolver tu FQDN completo (ej. `pve.midominio.local`). Si no es así, o si sigue mostrando `localhost`, **reinicia el servidor completo** para que los cambios se apliquen.

### Paso 3: Añadir el Repositorio de Proxmox VE

Añade el repositorio `pve-no-subscription` (la versión gratuita) y la clave GPG.

```bash
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list
```

Descarga e importa la clave GPG de Proxmox:

```bash
wget https://download.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
```

### Paso 4: Actualizar la Caché de APT

Ahora que el repositorio de Proxmox está añadido, actualiza la lista de paquetes.

```bash
sudo apt update
```

### Paso 5: Instalar Proxmox VE

Instala los paquetes principales de Proxmox VE, `postfix` (para enviar correos del sistema) y `open-iscsi` (para soporte de almacenamiento iSCSI).

```bash
sudo apt install proxmox-ve postfix open-iscsi -y
```

Durante la instalación de `postfix`, se te preguntará sobre la configuración del correo. Para la mayoría de los usuarios domésticos o instalaciones básicas, seleccionar "Internet Site" y proporcionar el FQDN de tu Proxmox VE (ej. `pve.midominio.local`) suele ser suficiente.

### Paso 6: (Opcional) Eliminar el Kernel de Debian

Proxmox instala su propio kernel optimizado para virtualización (la serie `pve-kernel`). Puedes eliminar el kernel genérico de Debian para evitar confusiones y liberar espacio.

```bash
sudo apt remove linux-image-amd64 linux-headers-amd64 -y
sudo update-grub
```
**Importante:** Asegúrate de que el kernel de Proxmox sea el kernel predeterminado en GRUB antes de eliminar el kernel de Debian. El comando `update-grub` debería manejar esto, pero si tienes dudas, puedes verificarlo en `/boot/grub/grub.cfg`.

### Paso 7: Reiniciar el Sistema

Un reinicio es esencial para que el nuevo kernel de Proxmox y todas las configuraciones tomen efecto.

```bash
sudo reboot
```

---

## ✅ Post-Instalación

1.  **Acceder a la Interfaz Web de Proxmox VE:**
    Abre tu navegador web y navega a la dirección IP de tu servidor Proxmox en el puerto 8006, usando HTTPS:
    ```
    https://TU_IP_PROXMOX:8006
    ```
    Aceptarás una advertencia de seguridad del navegador porque Proxmox usa un certificado autofirmado por defecto.

2.  **Iniciar Sesión:**
    *   **Usuario:** `root`
    *   **Contraseña:** La contraseña que estableciste durante la instalación de Debian.

3.  **Eliminar el Aviso de Suscripción (Opcional):**
    Si no tienes una suscripción, puedes eliminar el pop-up de "No valid subscription" que aparece al iniciar sesión. Edita el archivo `/etc/apt/sources.list.d/pve-enterprise.list`:

    ```bash
    sudo nano /etc/apt/sources.list.d/pve-enterprise.list
    ```
    Comenta la línea añadiendo un `#` al principio:

    ```
    # deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
    ```
    Luego, añade el repositorio `pve-no-subscription` si no lo hiciste antes o si lo borraste por error:
    ```bash
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-no-subscription.list
    sudo apt update
    ```

    Después de esto, el aviso no debería aparecer al iniciar sesión nuevamente.

---

##  troubleshooting (Problemas Comunes)

*   **`pve-cluster` o `pmxcfs` falla (Connection refused, Exception 255):**
    Casi siempre se debe a una configuración incorrecta de `hostname` o `/etc/hosts` donde el nombre del nodo no se resuelve a una IP real. Revisa los **Pasos 2.1 y 2.2** con mucho cuidado y asegúrate de que la línea `127.0.1.1` esté comentada en `/etc/hosts`. Un reinicio completo (`sudo reboot`) a menudo es necesario para aplicar estos cambios.

*   **`failed to load local private key` o `error updating firewall rules`:**
    Estos errores suelen ser una consecuencia directa de que `pve-cluster` no está funcionando. Una vez que `pve-cluster` esté estable (ver el punto anterior), reinicia los servicios:
    ```bash
    sudo systemctl restart pveproxy
    sudo systemctl restart proxmox-firewall
    ```
    Si los certificados SSL están dañados, puedes intentar regenerarlos: `sudo pvecm updatecerts -f`

*   **No puedo acceder a la interfaz web:**
    *   Verifica la IP de tu Proxmox con `ip a`.
    *   Asegúrate de usar `https://` y el puerto `:8006`.
    *   Verifica que el servicio `pveproxy` esté corriendo: `sudo systemctl status pveproxy`. Si no, revisa sus logs con `journalctl -u pveproxy -f`.
    *   Asegúrate de que no haya un firewall en tu router o en tu máquina host bloqueando el puerto 8006.

---

¡Felicidades! Ahora tienes Proxmox VE 8.4 funcionando en tu servidor Debian 12. Puedes empezar a crear máquinas virtuales y contenedores.