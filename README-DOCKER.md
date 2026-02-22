# 🏉 WesRugby - Sistema de Gestión

Sistema completo de gestión para el Club de Rugby Wessex, con backend Node.js, base de datos PostgreSQL, y frontend Flutter.

## 🚀 Quick Start con Docker

### Producción (VM/Servidor Local)

```bash
# Windows
.\deploy.bat

# Linux/Mac
chmod +x deploy.sh
./deploy.sh
```

### Desarrollo

```bash
# Copiar variables de entorno
cp .env.production.example .env

# Iniciar en modo desarrollo
docker-compose -f docker-compose.dev.yml up -d

# Ver logs
docker-compose -f docker-compose.dev.yml logs -f
```

## 📁 Estructura del Proyecto

```
WesRugby/
├── backend/                 # API Node.js + Express
│   ├── src/
│   │   ├── controllers/    # Lógica de negocio
│   │   ├── routes/         # Rutas de la API
│   │   ├── entity/         # Modelos de base de datos
│   │   └── ...
│   ├── Dockerfile          # Imagen Docker del backend
│   └── package.json
│
├── frontend/               # App móvil Flutter
│   ├── lib/
│   │   ├── features/       # Módulos por funcionalidad
│   │   ├── core/           # Configuración y servicios
│   │   └── shared/         # Componentes compartidos
│   └── pubspec.yaml
│
├── nginx/                  # Reverse proxy y load balancer
│   ├── nginx.conf
│   └── conf.d/
│       └── wesrugby.conf
│
├── docker-compose.yml      # Orquestación - Producción
├── docker-compose.dev.yml  # Orquestación - Desarrollo
├── .env.production.example # Template de variables de entorno
├── deploy.sh / deploy.bat  # Scripts de deployment
├── backup.sh               # Script de backups
└── DEPLOYMENT.md          # Guía completa de deployment
```

## 🛠️ Servicios Docker

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **Backend (Node.js)** | 3000 | API REST principal |
| **PostgreSQL** | 5432 | Base de datos |
| **Nginx** | 80, 443 | Reverse proxy |
| **API Raspberry Pi** | 8080 | Endpoint dedicado para inventario |
| **Adminer** (dev) | 8081 | Admin de base de datos |

## 📱 Frontend Flutter

El frontend es una aplicación móvil que se compila por separado:

```bash
cd frontend

# Instalar dependencias
flutter pub get

# Compilar para Android
flutter build apk --release

# Compilar para iOS
flutter build ios --release

# Ejecutar en desarrollo
flutter run
```

## 🔐 Configuración de Seguridad

### 1. Generar Claves Secretas

```bash
# Generar clave para ACCESS_TOKEN_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Copiar resultado al archivo .env
```

### 2. Configurar Firewall

**Puertos que DEBEN estar abiertos:**
- `80` (HTTP) - Acceso web general
- `8080` (API) - Raspberry Pi para inventario

**Puertos que NO deben exponerse al exterior:**
- `5432` (PostgreSQL) - Solo acceso interno entre contenedores
- `3000` (Backend directo) - Solo si es necesario para debugging

### 3. Restringir Acceso Raspberry Pi

Editar `nginx/conf.d/wesrugby.conf`:

```nginx
server {
    listen 8080;
    
    # Solo permitir IP de Raspberry Pi
    allow 192.168.1.100;  # Cambiar por tu IP
    deny all;
    
    # ... configuración
}
```

## 📊 Endpoints Principales

### API Backend

```
GET  /api/health                    # Health check
POST /api/auth/login               # Login
GET  /api/estudiantes              # Listar estudiantes
POST /api/comprobantes-pago        # Registrar pago
GET  /api/asistencia               # Consultar asistencia
POST /api/inventario               # Actualizar inventario
```

### Integración Raspberry Pi

```python
# Ejemplo desde Raspberry Pi
import requests

API_URL = "http://192.168.1.Y:8080/api"
API_KEY = "tu_api_key"

headers = {
    "X-API-Key": API_KEY,
    "Content-Type": "application/json"
}

# Actualizar inventario
response = requests.post(
    f"{API_URL}/inventario/update",
    json={"producto_id": 123, "cantidad": 50},
    headers=headers
)
```

## 💾 Backups

### Automático (Recomendado)

```bash
# Linux - Configurar cron para backup diario a las 2 AM
crontab -e
# Agregar: 0 2 * * * /ruta/completa/a/WesRugby/backup.sh
```

### Manual

```bash
# Backup completo
./backup.sh

# Solo base de datos
docker-compose exec -T postgres pg_dump -U postgres wesrugby > backup.sql

# Solo archivos
tar -czf uploads_backup.tar.gz backend/uploads/
```

## 🔧 Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Reiniciar un servicio
docker-compose restart backend

# Ver estado de servicios
docker-compose ps

# Acceder a la consola de PostgreSQL
docker-compose exec postgres psql -U postgres wesrugby

# Ver uso de recursos
docker stats

# Detener todo
docker-compose down

# Limpiar todo (⚠️ BORRA LA BASE DE DATOS)
docker-compose down -v
```

## 🧪 Testing

```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
flutter test
```

## 📚 Documentación Completa

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Guía completa de deployment y configuración
- **Backend API Docs** - Ver `/backend/README.md` (si existe)
- **Frontend Docs** - Ver `/frontend/README.md`

## 🆘 Troubleshooting

### Backend no se conecta a la base de datos

```bash
# Verificar logs
docker-compose logs postgres backend

# Verificar variables de entorno
docker-compose exec backend env | grep DB_
```

### Puerto en uso

```bash
# Verificar qué proceso usa el puerto
# Windows
netstat -ano | findstr :3000

# Linux
sudo lsof -i :3000
```

### No puedo acceder desde Raspberry Pi

```bash
# Verificar firewall
# Windows
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*WesRugby*"}

# Linux
sudo ufw status

# Probar conectividad
curl -v http://IP_DEL_SERVIDOR:8080/health
```

## 🔄 Actualizar Sistema

```bash
# Pull de cambios
git pull origin main

# Reconstruir y reiniciar
docker-compose build --no-cache
docker-compose up -d

# Verificar logs
docker-compose logs -f backend
```

## 🎯 Roadmap

- [ ] Implementar HTTPS con Let's Encrypt
- [ ] Agregar monitoreo con Prometheus + Grafana
- [ ] CI/CD con GitHub Actions
- [ ] Documentación automática de API con Swagger
- [ ] Tests automatizados con cobertura > 80%

## 👥 Equipo

- **Autor**: José Manríquez Ulloa
- **Proyecto**: WesRugby

## 📄 Licencia

ISC

---

## ⚡ Recomendaciones para Producción

### ✅ Antes de Pasar a Producción

1. **Cambiar todas las contraseñas y secretos** en `.env`
2. **Configurar backups automáticos**
3. **Implementar HTTPS** (Let's Encrypt)
4. **Restringir acceso** por IP a endpoints sensibles
5. **Configurar monitoreo** y alertas
6. **Documentar** procedimientos de emergencia
7. **Realizar pruebas de carga**
8. **Configurar logs centralizados**

### 🔒 Seguridad

- Nunca commitear archivos `.env` al repositorio
- Usar contraseñas fuertes y únicas
- Mantener Docker y dependencias actualizadas
- Revisar logs regularmente
- Implementar rate limiting (ya configurado)
- Usar HTTPS en producción

### 🚨 Contacto de Emergencia

Si algo falla en producción:

1. Revisar logs: `docker-compose logs -f`
2. Verificar estado: `docker-compose ps`
3. Hacer rollback si es necesario
4. Restaurar último backup

---

**¿Preguntas?** Revisa [DEPLOYMENT.md](DEPLOYMENT.md) para más detalles.
