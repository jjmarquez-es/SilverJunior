```markdown
# n8n Stack con Nginx Reverse Proxy (SSL Personalizado)

Este repositorio contiene la configuración para desplegar una instancia de **n8n** con soporte SSL mediante un proxy inverso Nginx, optimizado para Debian.

## 🚀 Instalación de Docker en Debian

Ejecuta estos comandos para preparar tu sistema:
```bash
# 1. Requisitos previos
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

# 2. Clave GPG de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL [https://download.docker.com/linux/debian/gpg](https://download.docker.com/linux/debian/gpg) | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Repositorio oficial
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] [https://download.docker.com/linux/debian](https://download.docker.com/linux/debian) \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

## 🛠️ Configuración de la Infraestructura

El despliegue se basa en una arquitectura de 4 contenedores:
*   **Nginx**: Gestiona el cifrado SSL y redirige el tráfico al puerto 5678 de n8n.
*   **n8n**: El motor de automatización.
*   **PostgreSQL**: Base de datos para persistencia de flujos.
*   **Redis**: Gestión de colas de mensajes para mejorar el rendimiento.

---

## 🔐 Personalización de Certificados SSL

Según los archivos proporcionados, el certificado se genera automáticamente durante la construcción de la imagen de Nginx. Si deseas cambiar el nombre de **`jumarque`** por otro, debes modificar los siguientes archivos:

### 1. En el `Dockerfile` (Carpeta `./nginx`)
Localiza la instrucción `RUN openssl` y cambia los nombres de salida[cite: 1]:
```dockerfile
# Cambia 'nombre_nuevo' por el tuyo
RUN openssl req -newkey rsa:4096 -x509 ... \
       -out /etc/nginx/ssl/nombre_nuevo.crt \
       -keyout /etc/nginx/ssl/nombre_nuevo.key \
       -subj "/C=SP/.../CN=nombre_nuevo/"
```

### 2. En la configuración de Nginx (`./nginx/conf/nginx.conf`)
Debes asegurarte de que las rutas coincidan exactamente con lo definido en el Dockerfile[cite: 2]:
```nginx
server {
    listen 443 ssl;
    server_name n8n.local; # Cambia por tu dominio

    # ESTOS NOMBRES DEBEN COINCIDIR CON EL DOCKERFILE
    ssl_certificate     /etc/nginx/ssl/nombre_nuevo.crt;
    ssl_certificate_key /etc/nginx/ssl/nombre_nuevo.key;
    
    # ... resto de la configuración
}
```

---

## 🔑 Variables de Entorno (.env)

Crea un archivo `.env` en la raíz con el siguiente contenido para que el `docker-compose.yml` funcione correctamente:

```env
# Datos de PostgreSQL
DB_POSTGRESDB_DATABASE=n8n_db
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=contraseña_segura_db

# Datos de Redis
REDIS_PASSWORD=contraseña_segura_redis
```

---

## 🏁 Despliegue

Para iniciar todo el sistema por primera vez:

```bash
# Construye la imagen de Nginx y levanta los servicios
sudo docker compose up -d --build
```

### Notas adicionales
*   **Healthchecks**: El sistema está configurado para que Nginx no arranque hasta que n8n esté listo, y n8n no arranque hasta que Postgres y Redis lo estén.
*   **Persistencia**: Se utilizan volúmenes con nombre (`n8n_data`, `n8n_postgres_data`, etc.) para que los datos no se borren al eliminar los contenedores.
```
