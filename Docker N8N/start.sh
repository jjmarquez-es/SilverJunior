#!/bin/bash
# Script de inicio para n8n
cd /home/cloudcoderuser/outline/n8n

echo "Iniciando servicios de n8n..."
docker compose -f /home/cloudcoderuser/outline/n8n/docker-compose.yml up -d

echo ""
echo "Esperando que los servicios inicien..."
sleep 10

echo ""
echo "Estado de los contenedores:"
docker ps | grep n8n

echo ""
echo "Para verificar logs:"
echo "  docker logs -f n8n_app"
echo ""
echo "Para detener:"
echo "  docker compose -f /home/cloudcoderuser/outline/n8n/docker-compose.yml down"