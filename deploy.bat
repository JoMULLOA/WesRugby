@echo off
REM Script de deployment para WesRugby - Windows
REM Autor: WesRugby Team

echo ========================================
echo   Deployment de WesRugby
echo ========================================
echo.

REM Verificar Docker
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker no esta instalado
    exit /b 1
)

docker-compose --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker Compose no esta instalado
    exit /b 1
)

REM Verificar .env
if not exist .env (
    echo [ADVERTENCIA] Archivo .env no encontrado
    echo Copiando .env.production.example a .env...
    copy .env.production.example .env
    echo.
    echo [IMPORTANTE] Edita el archivo .env con tus valores reales
    echo.
    set /p continue="Deseas continuar? (s/n): "
    if /i not "%continue%"=="s" exit /b 0
)

REM Crear directorios
echo [INFO] Creando directorios necesarios...
if not exist backend\uploads\avatars mkdir backend\uploads\avatars
if not exist backend\uploads\eventos mkdir backend\uploads\eventos
if not exist backend\uploads\imagenes mkdir backend\uploads\imagenes
if not exist backend\logs mkdir backend\logs
if not exist nginx\logs mkdir nginx\logs

REM Detener contenedores
echo [INFO] Deteniendo contenedores existentes...
docker-compose down

REM Limpiar recursos
echo [INFO] Limpiando recursos Docker antiguos...
docker system prune -f

REM Construir imágenes
echo [INFO] Construyendo imagenes Docker...
docker-compose build --no-cache

REM Iniciar servicios
echo [INFO] Iniciando servicios...
docker-compose up -d

REM Esperar
echo [INFO] Esperando a que los servicios esten listos...
timeout /t 10 /nobreak >nul

REM Verificar estado
echo.
echo [INFO] Estado de los servicios:
docker-compose ps

REM Mostrar logs
echo.
echo [INFO] Ultimos logs del backend:
docker-compose logs --tail=50 backend

echo.
echo ========================================
echo   Deployment completado exitosamente
echo ========================================
echo.
echo Servicios disponibles:
echo   - API Backend: http://localhost:3000/api
echo   - Nginx Proxy: http://localhost
echo   - PostgreSQL: localhost:5432
echo   - API Raspberry Pi: http://localhost:8080/api
echo.
echo Comandos utiles:
echo   - Ver logs: docker-compose logs -f
echo   - Detener: docker-compose down
echo   - Reiniciar: docker-compose restart
echo.
