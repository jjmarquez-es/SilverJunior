#!/bin/bash
set -e

echo "=========================================================="
echo "  SANEANDO PROYECTO PARA PRODUCCIÓN / GITHUB"
echo "=========================================================="

# 1. Purgar archivos y carpetas con datos personales o sensibles
echo "[1/6] Eliminando secretos, bases de datos reales y cachés..."
rm -rf __pycache__
rm -f tree.txt
rm -f .env .htpasswd
rm -f data/*.db data/*.db-wal data/*.db-shm
rm -rf users_data
rm -rf backups/*
rm -rf certbot/conf/*
# Eliminar solo los audios sueltos temporales en la raíz de generated_audio (conserva carpetas temáticas)
find generated_audio -maxdepth 1 -type f -name "tts_*.mp3" -exec rm -f {} +

# 2. Asegurar directorios requeridos y puntos de montaje de Docker
echo "[2/6] Creando directorios limpios y anclajes .gitkeep..."
mkdir -p html/generated_audio
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p backups
mkdir -p data

touch html/generated_audio/.gitkeep
touch certbot/conf/.gitkeep
touch certbot/www/.gitkeep
touch backups/.gitkeep
touch data/.gitkeep

# 3. Crear plantilla .env.example
echo "[3/6] Generando .env.example..."
cat << 'EOF' > .env.example
# ==========================================================
# CONFIGURACIÓN DE PRODUCCIÓN (ENGLISH TRAINER B2)
# ==========================================================

# Conexión con Ollama (ajustar según despliegue local o remoto)
OLLAMA_URL=http://host.docker.internal:11434/api/chat
OLLAMA_MODEL=qwen2.5:latest

# Clave simétrica Fernet de 32 bytes en Base64 para cifrado de SQLite
# Generar en Python: python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
DB_ENCRYPTION_KEY=CAMBIAR_POR_CLAVE_FERNET_32_BYTES_BASE64

# Dominio y correo para Certbot (Let's Encrypt)
DOMAIN_NAME=tu-dominio.com
CERTBOT_EMAIL=admin@tu-dominio.com
EOF

# 4. Crear .gitignore estricto
echo "[4/6] Configurando .gitignore..."
cat << 'EOF' > .gitignore
# Secretos y entorno local
.env
.htpasswd

# Base de datos SQLite activa y temporales WAL
data/*.db
data/*.db-wal
data/*.db-shm

# Datos privados de usuarios y copias de seguridad
users_data/
backups/*.gz
*.log

# Certificados y claves privadas SSL de Certbot
certbot/conf/*
!certbot/conf/.gitkeep

# Temporales de Python y sistema
__pycache__/
*.py[cod]
*$py.class
.DS_Store
tree.txt

# Puntos de anclaje obligatorios para Docker
!html/generated_audio/.gitkeep
!certbot/www/.gitkeep
!backups/.gitkeep
!data/.gitkeep
EOF

# 5. Reescribir docker-compose.yaml blindado para producción
echo "[5/6] Generando docker-compose.yaml limpio y modular..."
cat << 'EOF' > docker-compose.yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    container_name: english_api
    restart: unless-stopped
    env_file:
      - .env
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./data:/app/data
      - ./api_tracker.py:/app/api_tracker.py:ro
      - ./generated_audio:/app/generated_audio:rw
    networks:
      - english_net

  web:
    image: nginx:alpine
    container_name: english_web
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./generated_audio:/usr/share/nginx/html/generated_audio:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./certbot/www:/var/www/certbot:ro
    depends_on:
      - api
    networks:
      - english_net

  certbot:
    image: certbot/certbot
    container_name: english_certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12d & wait $${!}; done;'"

networks:
  english_net:
    driver: bridge
EOF

# 6. Adaptar backup.sh para rutas relativas
echo "[6/6] Ajustando backup.sh a rutas relativas..."
cat << 'EOF' > backup.sh
#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="${BASE_DIR}/backups"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BACKUP_NAME="neural_deck_${TIMESTAMP}.db"
CONTAINER_NAME="english_api"
RETENTION_DAYS=14

mkdir -p "${BACKUP_DIR}"

docker exec "${CONTAINER_NAME}" python3 -c "
import sqlite3
conn = sqlite3.connect('/app/data/neural_deck.db')
conn.execute(\"VACUUM INTO '/app/data/${BACKUP_NAME}'\")
conn.close()
"

mv "${BASE_DIR}/data/${BACKUP_NAME}" "${BACKUP_DIR}/${BACKUP_NAME}"
gzip -9 "${BACKUP_DIR}/${BACKUP_NAME}"
find "${BACKUP_DIR}" -type f -name "neural_deck_*.db.gz" -mtime +${RETENTION_DAYS} -exec rm -f {} \;
EOF
chmod +x backup.sh

echo "=========================================================="
echo "  PROYECTO LISTO: Puedes inicializar Git y subirlo a GitHub."
echo "=========================================================="