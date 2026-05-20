```markdown
# Debian 13 (Trixie) en MacBook Pro 7,1 (Mid-2010) 🐧💻

Este repositorio contiene una guía completa de post-instalación para configurar **Debian 13** en un **MacBook Pro 7,1** (13 pulgadas, Mid-2010). El objetivo es lograr un sistema estable, optimizado para el desarrollo de software y totalmente compatible con los estándares de **École 42**.

---

## 🚀 1. Repositorios Iniciales
Para instalar controladores propietarios (Wi-Fi, Firmware), primero activa los repositorios `non-free`.

1. Edita `/etc/apt/sources.list`:
   ```bash
   sudo nano /etc/apt/sources.list

```

2. Asegúrate de que las líneas incluyan: `main contrib non-free non-free-firmware`.
3. Actualiza el sistema:
```bash
sudo apt update && sudo apt upgrade -y

```



---

## 🔧 2. Hardware y Drivers

### 📶 Wi-Fi (Broadcom BCM4322)

Instala el controlador `wl` (propietario):

```bash
sudo apt install linux-headers-$(uname -r) broadcom-sta-dkms
sudo modprobe -r b44 b43 b43legacy ssb brcmsmac bcma
sudo modprobe wl

```

### ❄️ Control del Ventilador (mbpfan)

Evita el sobrecalentamiento gestionando las RPM de forma inteligente:

```bash
sudo apt install mbpfan
sudo systemctl enable mbpfan
sudo systemctl start mbpfan

```

### 🖱️ Touchpad (Gestos y Clic)

Para una sensación "macOS" con desplazamiento natural y clic derecho con dos dedos:

```bash
sudo apt install xserver-xorg-input-libinput touchegg
sudo systemctl enable --now touchegg

```

*Tip: Configura el "Desplazamiento Natural" en los ajustes de Ratón/Panel Táctil de tu entorno de escritorio.*

---

## 🛠️ 3. Entorno de Desarrollo (Estilo École 42)

Todo lo necesario para superar la **Piscine** y el **Common Core**.

### Herramientas Core y Compilación

```bash
sudo apt install build-essential valgrind gdb lldb clang zsh git

```

### Librerías para Proyectos Gráficos (MLX)

Indispensables para proyectos como *so_long*, *FdF* o *fract-ol*:

```bash
sudo apt install libx11-dev libxext-dev libbsd-dev

```

### Software de Apoyo

* **Norminette:** `python3 -m pip install norminette`
* **Docker:** Para proyectos como *Inception*.
```bash
sudo apt install docker.io docker-compose

```



---

## ⌨️ 4. Atajos y Teclado

Para controlar la retroiluminación del teclado:

```bash
sudo apt install light brightd

```

### Header de 42

Si usas **VS Code**, instala la extensión `42 Header` y configura tu login:

1. `Ctrl + Shift + P` -> "42 Header: Settings"
2. Define tu `User` y `Email`.
3. Inserta el header con `Ctrl + Alt + H`.

---

## 📝 Notas Adicionales

* **Gráficos:** El MacBook 7,1 usa la **NVIDIA GeForce 320M**. El driver libre `nouveau` funciona bien en Debian 13, pero si necesitas el driver privativo `nvidia-340xx`, ten en cuenta que es "legacy" y requiere parches para kernels modernos.
* **Audio:** Si el micrófono interno no funciona, añade `options snd-hda-intel model=mbp71` a `/etc/modprobe.d/alsa-base.conf`.

---

*Guía creada para la comunidad de 42 y entusiastas de Linux en hardware antiguo.* 🚀

```

---
#!/bin/bash

# Script para reparar el Wi-Fi Broadcom (wl) en Debian/Ubuntu
# Útil tras actualizaciones de Kernel en MacBook Pro

VERSION_DRIVER="6.30.223.271"
KERNEL_ACTUAL=$(uname -r)

echo "--- Reparador de Wi-Fi para MacBook (Broadcom STA) ---"
echo "Detectado Kernel: $KERNEL_ACTUAL"

# 1. Comprobar si el módulo ya está cargado
if lsmod | grep -q "wl"; then
    echo "[!] El módulo 'wl' ya está cargado. Reiniciando interfaz..."
    sudo modprobe -r wl && sudo modprobe wl
    exit 0
fi

echo "[...] Intentando cargar el módulo 'wl'..."
if sudo modprobe wl 2>/dev/null; then
    echo "[OK] Wi-Fi activado correctamente."
else
    echo "[!] Error: Módulo no encontrado. Iniciando compilación con DKMS..."
    
    # 2. Eliminar posibles conflictos
    echo "[...] Eliminando drivers en conflicto (b43, bcma, ssb)..."
    sudo modprobe -r b43 bcma ssb 2>/dev/null
    
    # 3. Forzar instalación en el kernel actual
    echo "[...] Compilando driver para el kernel $KERNEL_ACTUAL..."
    sudo dkms install -m broadcom-sta -v $VERSION_DRIVER -k $KERNEL_ACTUAL
    
    # 4. Intentar cargar de nuevo
    if sudo modprobe wl; then
        echo "[OK] ¡Wi-Fi reparado y funcionando!"
    else
        echo "[X] Error crítico: No se pudo cargar el driver. Revisa 'dmesg'."
    fi
fi
