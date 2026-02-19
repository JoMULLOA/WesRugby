#!/bin/bash

# Script de backup para WesRugby
# Realiza backup de la base de datos y archivos importantes

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_BACKUP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
FILES_BACKUP_FILE="$BACKUP_DIR/files_backup_$TIMESTAMP.tar.gz"

echo "🔄 Iniciando backup de WesRugby..."

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Backup de la base de datos
echo "💾 Realizando backup de la base de datos..."
docker-compose exec -T postgres pg_dump -U postgres wesrugby > "$DB_BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup de base de datos completado: $DB_BACKUP_FILE"
else
    echo "❌ Error al realizar backup de la base de datos"
    exit 1
fi

# Backup de archivos (uploads)
echo "📁 Realizando backup de archivos..."
tar -czf "$FILES_BACKUP_FILE" backend/uploads/

if [ $? -eq 0 ]; then
    echo "✅ Backup de archivos completado: $FILES_BACKUP_FILE"
else
    echo "❌ Error al realizar backup de archivos"
    exit 1
fi

# Limpiar backups antiguos (mantener solo los últimos 7 días)
echo "🧹 Limpiando backups antiguos..."
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "✅ Backup completado exitosamente!"
echo "📊 Resumen:"
echo "   - Base de datos: $DB_BACKUP_FILE"
echo "   - Archivos: $FILES_BACKUP_FILE"
