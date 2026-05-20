# 🚀 Ollama en Proxmox: Tu Laboratorio Local de LLMs (CPU-Only) 🧠

![Ollama Logo](https://ollama.com/public/ollama.png)
![Proxmox Logo](https://www.proxmox.com/images/proxmox/Proxmox_logo_standard_hex_400px.png#joomlaImage://local-images/proxmox/Proxmox_logo_standard_hex_400px.png?width=400&height=60)

Este repositorio documenta los pasos para configurar una máquina virtual (VM) en **Proxmox VE** optimizada para ejecutar **Ollama** en modo **CPU-Only**. Ideal para quienes desean experimentar con Large Language Models (LLMs) localmente, aprovechando la virtualización y recursos como CPU y RAM de su servidor, sin necesidad de una GPU dedicada de alto rendimiento.

## 🌟 Características Principales de esta Configuración

*   **Hypervisor:** Proxmox VE (probado en versiones 7.x y 8.x)
*   **Sistema Operativo de la VM:** Debian 12 "Bookworm" (Estable)
*   **Motor de LLMs:** Ollama
*   **Recursos de la VM:**
    *   **RAM:** 16-20 GB (ajustable según el host, optimizado para evitar *swapping*)
    *   **CPU:** 4-6 hilos (para hosts con Intel i7 de 4ta generación o similar)
    *   **Almacenamiento:** Mínimo 60 GB (los modelos LLM consumen espacio)
*   **Enfoque:** Ejecución **exclusiva en CPU** (sin passthrough de GPU).
*   **Optimización clave:** Deshabilitación de swap en la VM para un rendimiento de inferencia más consistente.

## 🎯 ¿Por qué Ollama en Proxmox (CPU-Only)?

*   **Privacidad y Control:** Ejecuta LLMs en tu propio hardware sin enviar datos a la nube.
*   **Experimentación Flexible:** Crea y gestiona fácilmente diferentes entornos para LLMs gracias a la virtualización de Proxmox.
*   **Aprovechamiento de Recursos:** Maximiza el uso de tu servidor Proxmox, incluso si no tienes una GPU potente.
*   **Aprendizaje y Desarrollo:** Una plataforma perfecta para probar modelos, integrar LLMs en tus aplicaciones o simplemente explorar las capacidades de la IA.

## 📋 Prerequisitos

Antes de empezar, asegúrate de tener:

*   Un servidor con **Proxmox VE** instalado y funcionando.
*   **Mínimo 32 GB de RAM** en el servidor host.
*   **CPU Intel i7 de 4ta generación o superior** con virtualización (VT-x) habilitada en la BIOS.
*   Espacio en disco suficiente (4 TB o más).
*   Conexión a internet para descargar las ISOs de Debian y los modelos de Ollama.

## ⚙️ Guía de Configuración Paso a Paso

### Fase 1: Preparación del Hardware (BIOS del Servidor Proxmox)

1.  Accede al BIOS/UEFI de tu servidor Proxmox.
2.  Habilita la **tecnología de virtualización Intel VT-x** (o AMD-V si tu CPU es AMD).
3.  **No es necesario habilitar VT-d (Intel IOMMU) ni IOMMU (AMD)**, ya que no se realizará passthrough de GPU.
4.  Guarda los cambios y reinicia el servidor.

### Fase 2: Creación de la Máquina Virtual (VM) en Proxmox

1.  Inicia sesión en la interfaz web de Proxmox ( `https://<IP_PROXMOX>:8006` ).
2.  Haz clic en **"Create VM"** (Crear VM).
3.  **Pestaña General:**
    *   **Node:** Selecciona tu nodo.
    *   **VM ID:** Asigna un ID único (ej. `100`).
    *   **Name:** `Ollama-Node` (o un nombre descriptivo).
4.  **Pestaña OS (Sistema Operativo):**
    *   **ISO image:** Selecciona el archivo ISO de **Debian 12 "Bookworm"** (descargado previamente y subido a tu almacenamiento de Proxmox).
    *   **Guest OS Type:** Linux.
    *   **Version:** 6.x - 2.6 Kernel.
5.  **Pestaña System (Sistema):**
    *   **Graphic card:** `Default` (o `std`).
    *   **SCSI Controller:** `VirtIO SCSI single`.
    *   **Machine:** Selecciona **`q35`** (la opción más moderna y recomendada).
    *   **BIOS:** `OVMF (UEFI)` (preferible para sistemas modernos) o `SeaBIOS`. Si eliges UEFI, recuerda añadir un `EFI Disk` al crear el disco.
    *   **Qemu Agent:** Marca **"Enabled"** (instalarás el agente más tarde en Debian).
6.  **Pestaña Disks (Discos):**
    *   **Bus/Device:** `SCSI` (con VirtIO SCSI Controller).
    *   **Storage:** Selecciona tu almacenamiento preferido (ej. `local-lvm`).
    *   **Disk Size:** Mínimo **60 GB** (los modelos LLM ocupan bastante espacio).
    *   **Cache:** `Write back` (para mejor rendimiento, con el riesgo de pérdida de datos si hay corte de energía).
    *   **Discard:** Marca **"Discard"** (para SSDs/NVMe, mejora la gestión del espacio).
7.  **Pestaña CPU:**
    *   **Sockets:** `1`.
    *   **Cores:** **`4` a `6`** (si tu host tiene 8 hilos, no asignes todos para dejar recursos al Proxmox).
    *   **Type:** `host` (para exponer las características completas de tu CPU física al invitado).
8.  **Pestaña Memory (Memoria):**
    *   **Memory (MiB):** Asigna **`18000` MB (18 GB)** o **`20000` MB (20 GB)**. Deja suficiente RAM (10-14 GB) para el sistema host de Proxmox.
9.  **Pestaña Network (Red):**
    *   **Bridge:** `vmbr0` (o el bridge que uses para acceso externo).
    *   **Model:** `VirtIO (paravirtualized)`.
10. **Confirma y finaliza la creación de la VM.**

### Fase 3: Instalación de Debian 12 "Bookworm" en la VM

1.  Inicia la VM desde la interfaz de Proxmox.
2.  Sigue el proceso estándar de instalación de Debian 12.
    *   Elige una instalación "Graphical install".
    *   Crea un usuario no root y establece una contraseña para `root`.
    *   En la selección de software, puedes desmarcar "Desktop environment" y "print server" para una instalación mínima, dejando solo "SSH server" y "standard system utilities".
3.  Una vez finalizada la instalación, reinicia la VM.

### Fase 4: Optimización de la VM para Ollama (CPU-Only)

Accede a la VM por SSH (usando la IP asignada a la VM) o desde la consola de Proxmox.

1.  **Actualizar el sistema:**
    ```bash
    sudo apt update
    sudo apt upgrade -y
    sudo apt install qemu-guest-agent -y # Instala el QEMU Guest Agent si lo habilitaste en Proxmox
    sudo systemctl enable qemu-guest-agent --now
    ```
2.  **¡CRÍTICO! Deshabilitar Swap:** Para LLMs en CPU, el swap ralentiza drásticamente el rendimiento.
    ```bash
    # Desactivar swap existente
    sudo swapoff -a

    # Comentar la línea de swap en /etc/fstab para que no se active en futuros arranques
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    # Ajustar vm.swappiness (aunque con swapoff -a, es menos crítico, pero buena práctica)
    echo "vm.swappiness=0" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # Ajustar overcommit_memory para permitir que las apps reserven mucha RAM
    echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    ```

### Fase 5: Instalación de Ollama en Debian

1.  **Instalar Ollama:**
    ```bash
    curl -fsSL https://ollama.ai/install.sh | sh
    ```
    Este script instala Ollama y lo configura como un servicio de `systemd`.

2.  **Verificar el servicio:**
    ```bash
    systemctl status ollama
    ```
    Debería mostrar `active (running)`.

### Fase 6: Descargar y Ejecutar Modelos LLM

1.  **Descargar un modelo (ej. Llama 3 8B de 4 bits cuantizado):**
    ```bash
    ollama run llama3:8b-instruct-q4_k_m
    ```
    Ollama descargará el modelo. Esto puede tardar varios minutos dependiendo de tu conexión a internet. Una vez descargado, podrás empezar a interactuar con él directamente en la terminal.

2.  **Probar el modelo:**
    ```bash
    ollama run llama3:8b-instruct-q4_k_m "¿Cuál es la capital de Francia?"
    ```

3.  **Exponer Ollama a la red local (opcional):**
    Por defecto, Ollama solo escucha en `localhost:11434`. Si quieres acceder desde otras máquinas en tu red:
    ```bash
    # Edita el archivo de configuración del servicio
    sudo systemctl edit ollama.service

    # Añade estas líneas al final para sobrescribir la configuración:
    # [Service]
    # Environment="OLLAMA_HOST=0.0.0.0"

    # Guarda y cierra el editor. Luego recarga y reinicia el servicio:
    sudo systemctl daemon-reload
    sudo systemctl restart ollama
    ```
    Ahora podrás acceder a la API de Ollama desde otras máquinas en tu red usando `http://<IP_DE_LA_VM>:11434`.

## 📈 Rendimiento Esperado (CPU i7 Gen4)

*   **Modelos pequeños (ej. Phi-3 Mini, Llama3 8B cuantizado):** Funcionarán, pero la generación de tokens será notablemente más lenta que con una GPU moderna. Espera unos pocos tokens por segundo (t/s).
*   **Modelos grandes (más de 10-12 GB):** Podrían ser muy lentos o incluso inestables debido al consumo excesivo de RAM y la carga en la CPU.
*   **Recomendación:** Prioriza modelos con cuantizaciones `q4_k_m` o `q2_k` para optimizar el uso de RAM y CPU.

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras mejoras o tienes sugerencias, no dudes en abrir un *issue* o enviar un *pull request*.

## 📄 Licencia

Este proyecto está bajo la licencia [MIT](LICENSE).