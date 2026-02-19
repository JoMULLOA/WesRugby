#!/bin/bash

# Script de deployment para WesRugby
# Autor: WesRugby Team
# Descripción: Despliega la aplicación en producción

set -e

echo "🚀 Iniciando deployment de WesRugby..."

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker no está instalado${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose no está instalado${NC}"
    exit 1
fi

# Verificar si existe .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado${NC}"
    echo "Copiando .env.production.example a .env..."
    cp .env.production.example .env
    echo -e "${YELLOW}⚠️  Por favor edita el archivo .env con tus valores reales${NC}"
    echo "¿Deseas continuar? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        exit 0
    fi
fi

# Crear directorios necesarios
echo "📁 Creando directorios necesarios..."
mkdir -p backend/uploads/avatars
mkdir -p backend/uploads/eventos
mkdir -p backend/uploads/imagenes
mkdir -p backend/logs
mkdir -p nginx/logs

# Detener contenedores existentes
echo "🛑 Deteniendo contenedores existentes..."
docker-compose down

# Limpiar contenedores e imágenes antiguas
echo "🧹 Limpiando recursos Docker antiguos..."
docker system prune -f

# Construir imágenes
echo "🔨 Construyendo imágenes Docker..."
docker-compose build --no-cache

# Iniciar servicios
echo "🚀 Iniciando servicios..."
docker-compose up -d

# Esperar a que los servicios estén listos
echo "⏳ Esperando a que los servicios estén listos..."
sleep 10

# Verificar estado de los servicios
echo "📊 Estado de los servicios:"
docker-compose ps

# Verificar logs
echo ""
echo "📋 Últimos logs del backend:"
docker-compose logs --tail=50 backend

echo ""
echo -e "${GREEN}✅ Deployment completado exitosamente!${NC}"
echo ""
echo "🌐 Servicios disponibles:"
echo "   - API Backend: http://localhost:3000/api"
echo "   - Nginx Proxy: http://localhost"
echo "   - PostgreSQL: localhost:5432"
echo "   - API Raspberry Pi: http://localhost:8080/api"
echo ""
echo "📝 Comandos útiles:"
echo "   - Ver logs: docker-compose logs -f"
echo "   - Detener: docker-compose down"
echo "   - Reiniciar: docker-compose restart"
echo ""
