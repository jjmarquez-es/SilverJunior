# PCI Passthrough en Proxmox (Debian 12)

Este repositorio contiene la guía técnica y los archivos de configuración necesarios para realizar un **PCI Passthrough** exitoso en servidores Proxmox basados en Debian 12. Este proyecto forma parte de mi proceso de documentación como **Junior a los cuarenta y muchos**.

## 🚀 Objetivo
Lograr que una máquina virtual (VM) acceda directamente al hardware físico (GPU, tarjetas de red, etc.), eliminando la capa de emulación para obtener un rendimiento nativo.

## 🛠️ Requisitos previos
- **Hardware:** Soporte para IOMMU (Intel VT-d o AMD-Vi) habilitado en la BIOS/UEFI.
- **Sistema Operativo:** Proxmox VE (basado en Debian 12 Bookworm).

## 📝 Configuración Paso a Paso

### 1. Activación de IOMMU
Edita el cargador de arranque:
`sudo nano /etc/default/grub`

Modifica la línea `GRUB_CMDLINE_LINUX_DEFAULT` según tu procesador:
- **Intel:** `intel_iommu=on iommu=pt`
- **AMD:** `amd_iommu=on iommu=pt`

Actualiza y reinicia:
```bash
sudo update-grub
sudo reboot
```

### 2. Carga de Módulos VFIO

Añade los módulos necesarios al kernel editando `/etc/modules`:

```text
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

```

### 3. Aislamiento de Hardware (Blacklist)

Para evitar que el sistema anfitrión use el dispositivo que queremos pasar, creamos un archivo de lista negra:
`sudo nano /etc/modprobe.d/pve-blacklist.conf`

Añade los drivers a bloquear (ejemplo para NVIDIA y AMD):

```text
blacklist nvidia
blacklist nouveau
blacklist radeon

```

### 4. Verificación técnica

Una vez reiniciado, comprueba que el driver en uso para el dispositivo es `vfio-pci`:

```bash
lspci -nnk

```

## 🔗 Enlaces y Recursos

* **Sitio Web:** [jjmarquez.es](https://www.jjmarquez.es)
* **YouTube:** [@jjmarquez-es](https://www.youtube.com/@jjmarquez-es)
* **LinkedIn:** [jjmarquez-es](https://www.linkedin.com/in/jjmarquez-es)

---

*Mantenido por Juan Jesús (jjmarquez-es). Documentando el camino de un #SilverJunior.*

```

```
