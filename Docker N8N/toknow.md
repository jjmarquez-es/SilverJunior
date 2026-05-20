¡Perfecto! Aquí va el resumen de todo lo que se necesitó para que funcionara:

---

## Resumen de configuración n8n con Docker

### `.env` final correcto

```env
# === DATABASE ===
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=tu_password

# === REDIS ===
REDIS_PASSWORD=tu_password_redis
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PORT=6379
QUEUE_BULL_REDIS_PASSWORD=tu_password_redis

# === ENCRYPTION KEY ===
N8N_ENCRYPTION_KEY=clave_minimo_32_caracteres

# === PUERTO Y URL ===
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=0.0.0.0
N8N_PATH=/
N8N_EDITOR_BASE_URL=http://localhost:5678/
WEBHOOK_TUNNEL_URL=http://localhost:5678/

# === SEGURIDAD ===
N8N_SECURE_COOKIE=false
N8N_BLOCK_ENV_ACCESS_IN_NODE=false
N8N_TRUST_PROXY=true

# === ZONA HORARIA ===
GENERIC_TIMEZONE=Europe/Madrid

# === EJECUCIONES ===
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168

# === FUNCIONES ===
NODE_FUNCTION_ALLOW_BUILTIN=*
NODE_FUNCTION_ALLOW_EXTERNAL=*
N8N_PAYLOAD_SIZE_MAX=8
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
```

---

### Errores clave y sus soluciones

**1. Database connection timeout** — el volumen de Postgres tenía credenciales de una instalación anterior. Solución: `docker compose down -v` para borrar volúmenes y recrear.

**2. `QUEUE_BULL_REDIS_PASSWORD=${REDIS_PASSWORD}`** — Docker no expande variables dentro del `.env`. Hay que poner el valor literal directamente.

**3. `REDIS_PASSWORD` no definida** — el `docker-compose.yml` la usa para el comando de Redis, así que debe estar en el `.env` aunque también esté `QUEUE_BULL_REDIS_PASSWORD`.

**4. Pantalla negra** — causada por `N8N_HOST=n8n.local` y `N8N_EDITOR_BASE_URL=https://n8n.local/` cuando el navegador accedía por `localhost`. n8n generaba URLs internas apuntando a `n8n.local` con certificado autofirmado que el navegador rechazaba.

**5. Assets cargando desde `/home/assets/`** — consecuencia del punto anterior. Al corregir `N8N_EDITOR_BASE_URL=http://localhost:5678/` se resolvió.

**6. `N8N_RUNNERS_ENABLED`** — variable deprecada, hay que eliminarla del `.env`.

**7. Variables duplicadas** — `N8N_PORT` y `N8N_SECURE_COOKIE` estaban definidas dos veces con valores distintos, causando comportamiento inesperado.

---

### nginx — configuración mínima necesaria

```nginx
location /ws {
    proxy_pass http://n8n:5678;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 3600s;
}

location / {
    proxy_pass http://n8n:5678;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For "";
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 300s;
}
```

Los puntos críticos de nginx son el bloque `/ws` para WebSockets y anular `X-Forwarded-For` para evitar el error de `express-rate-limit`.
