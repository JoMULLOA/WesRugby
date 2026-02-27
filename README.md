<div align="center">

# WesRugby

**Sistema de Gestión Integral · Club de Rugby Wessex**

[![CI Backend](https://github.com/JoMULLOA/WesRugby/actions/workflows/ci-backend.yml/badge.svg)](https://github.com/JoMULLOA/WesRugby/actions/workflows/ci-backend.yml)
[![CI Frontend](https://github.com/JoMULLOA/WesRugby/actions/workflows/ci-frontend.yml/badge.svg)](https://github.com/JoMULLOA/WesRugby/actions/workflows/ci-frontend.yml)
[![Deploy](https://github.com/JoMULLOA/WesRugby/actions/workflows/deploy.yml/badge.svg)](https://github.com/JoMULLOA/WesRugby/actions/workflows/deploy.yml)
[![Security Scan](https://github.com/JoMULLOA/WesRugby/actions/workflows/security-scan.yml/badge.svg)](https://github.com/JoMULLOA/WesRugby/actions/workflows/security-scan.yml)

🌐 **Producción:** [wesrugby.site](https://wesrugby.site)

*Proyecto de Título · Ingeniería Civil en Informática · Universidad del Bío-Bío · 2025*

</div>

---

## ¿Qué es WesRugby?

WesRugby centraliza en una sola plataforma **toda la operación del Club de Rugby Wessex**: cobros, asistencias, eventos, comunicaciones, inventario físico y punto de venta, eliminando el caos de planillas Excel, grupos de WhatsApp y cuadernos de papel.

El proyecto está **desplegado en producción** en [wesrugby.site](https://wesrugby.site) con un pipeline CI/CD completo sobre GitHub Actions: cada `push` a la rama de producción ejecuta los tests, compila el frontend Flutter para Web, despliega vía SSH y hace rollback automático si algo falla.

---

## Pipeline CI/CD — GitHub Actions

El repositorio cuenta con **7 workflows** que automatizan desde la validación de código hasta el respaldo nocturno de la base de datos.

```
push → mainProduccion
       │
       ├─► [ci-backend]    ESLint + Vitest unit tests + Vitest integration tests
       │                   (PostgreSQL 16 real como service container en CI)
       │
       ├─► [ci-frontend]   flutter analyze + flutter test --coverage
       │
       └─► [deploy]        (solo si todos los tests pasan)
                │
                ├─ Build Flutter Web → artefacto GitHub
                ├─ SSH al VPS → git reset --hard → docker compose up --build
                ├─ Inyección del build en Nginx
                ├─ Health check (curl /health)
                └─ Rollback automático al commit anterior si falla
```

| Workflow | Disparador | Acción |
|---|---|---|
| `ci-backend` | push / PR a `main` | ESLint · Vitest unit · Vitest integration contra PostgreSQL real |
| `ci-frontend` | push / PR a `main` | `flutter analyze` · `flutter test --coverage` |
| `deploy` | push a `mainProduccion` | Tests → Build → SSH deploy → Health check → Rollback |
| `pr-checks` | apertura de PR | Conventional commits · tamaño del PR · detección de archivos sensibles |
| `security-scan` | push + lunes 9AM UTC | npm audit · TruffleHog secrets scan · CodeQL SAST |
| `docker-build` | push | Verifica que la imagen Docker construye sin errores |
| `cron-backup` | 02:00 UTC diario | `pg_dump` en el servidor + limpieza de backups de más de 30 días |

---

## Arquitectura

```
                      ┌──────────────────────────────┐
                      │        wesrugby.site          │
                      │   Cloudflare  (HTTPS / WAF)   │
                      └─────────────┬────────────────┘
                                    │
                      ┌─────────────▼────────────────┐
                      │       Nginx  (Alpine)         │
                      │  Reverse proxy · Rate limit   │
                      │  Servir Flutter Web (SPA)     │
                      └──────┬───────────┬────────────┘
                             │ /api      │ /socket.io
               ┌─────────────▼───────────▼────────┐
               │         Node.js  API              │
               │  Express · Passport JWT · CORS    │
               │  Socket.IO (notificaciones RT)    │
               │  Nodemailer · node-cron · Multer  │
               └──────────────┬────────────────────┘
                              │ TypeORM
               ┌──────────────▼────────────────────┐
               │        PostgreSQL 16               │
               │   (puerto no expuesto al exterior) │
               └───────────────────────────────────┘

         ──── red local del club ────────────────────

               ┌──────────────────┐
               │   Raspberry Pi   │  ← Punto de venta físico
               │  Lector USB de   │     (kiosco del club)
               │  códigos de      │
               │  barras          │
               └────────┬─────────┘
                        │ REST / JSON
               ┌────────▼─────────┐
               │   Flutter App    │  ← Simulador de kiosco
               │  /inventario/    │     también disponible
               │  simulador       │     en la web
               └──────────────────┘
```

Todos los servicios corren como contenedores Docker orquestados con `docker-compose`, con healthchecks y política de reinicio automático.

---

## Sistema de Inventario y Kiosco (Raspberry Pi)

Una de las piezas más singulares del proyecto es la **integración con hardware local**: una Raspberry Pi actúa como punto de venta en el kiosco del club, conectada a un lector de códigos de barras USB.

### Flujo completo

1. **Alta de productos** — La Directiva o Tesorera crea productos en la app (nombre, categoría, precio). El backend genera un barcode interno único por categoría (`BL4F2A1C93` para bebidas latas, `PA...` para pastelería, etc.) con checksum personalizado para evitar colisiones.

2. **Impresión de etiquetas** — `npm run print:sheet` genera un PDF A4 con una cuadrícula de barcodes Code 128, listos para imprimir, recortar y pegar en los productos físicos del kiosco.

3. **Punto de venta (Raspberry Pi)** — La Pi corre la aplicación Flutter en modo kiosco. El lector USB escanea el barcode → la app consulta `/api/inventario/products` → muestra nombre y precio → registra la venta contra la API central.

4. **Precios variables** — Los productos marcados como `pricingMode: variable` (sandwichs, papas recién fritas, etc.) abren un campo de precio libre en el kiosco antes de confirmar la venta.

5. **Consolidación en tiempo real** — Todas las ventas se sincronizan con la API central. La Directiva y Tesorera ven el resumen actualizado desde la app móvil al instante, sin importar desde qué dispositivo se hizo la venta.

### Endpoints del módulo de inventario

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/inventario/products` | Productos activos (uso del kiosco) |
| `GET` | `/api/inventario/products/management` | Todos los productos + inactivos (panel admin) |
| `POST` | `/api/inventario/products` | Crear o actualizar producto |
| `DELETE` | `/api/inventario/products/:id` | Soft delete |
| `DELETE` | `/api/inventario/products/:id/permanent` | Eliminación permanente |
| `POST` | `/api/inventario/scans/bulk` | Ingesta de escaneos desde el kiosco |
| `POST` | `/api/inventario/sales/varios` | Venta de precio libre |
| `GET` | `/api/inventario/sales/summary` | Resumen de ventas del período |
| `GET` | `/api/inventario/sheet` | Genera PDF con barcodes (stream directo) |

---

## Testing

La suite de tests está organizada en **dos niveles independientes**, cada uno con su propia configuración de Vitest:

### Tests unitarios — `npm test`

Corren en paralelo, sin base de datos. Cubren validaciones de esquemas Joi, handlers de respuesta HTTP y lógica de negocio aislada.

```
tests/
├── handlers/       responseHandlers.test.js
├── helpers/        bcrypt, tokens
├── utils/          generación de barcodes, helpers de PDF
└── validations/    auth.validation.test.js · inventory.schemas.test.js
```

### Tests de integración — `npm run test:integration`

Levantan una instancia real de PostgreSQL 16 (service container en CI, Docker en local), sincronizan el schema con TypeORM y ejecutan peticiones HTTP reales sobre la aplicación Express con Supertest.

```
tests/integration/
├── auth.integration.test.js
│   └── registro · login · refresh token · logout · rutas protegidas
└── inventory.integration.test.js
    └── CRUD productos · escaneos bulk · ventas · resumen · PDF stream
```

**Diseño de aislamiento para tests de integración:**
- `pool: forks` + `singleFork: true` — un solo proceso hijo comparte la conexión TypeORM entre todos los archivos de test
- `fileParallelism: false` — ejecución en serie, evitando TRUNCATEs simultáneos que corromperían los datos
- Cada suite limpia y re-siembra sus datos antes de correr (`beforeAll`)

### Tests del frontend — `flutter test --coverage`

Suite de tests unitarios Dart con reporte de cobertura, ejecutada en CI en cada push.

---

## Centralización de información

WesRugby unifica en una sola fuente de verdad datos que antes vivían dispersos en el club:

| Antes | Con WesRugby |
|---|---|
| Planilla Excel de pagos | Comprobantes validados por rol con estados y archivos adjuntos (S3 / local) |
| Lista de asistencia en papel | Sesiones de asistencia digitales con justificantes y registro de meses exentos |
| Inventario en cuaderno | Inventario con barcodes, categorías, precios y resumen de ventas en tiempo real |
| Notificaciones por WhatsApp | Notificaciones in-app por rol con conteo de pendientes (Socket.IO) |
| Eventos anotados en agenda | Módulo de eventos, torneos, actas de reunión y multimedia |
| Contactos dispersos | Directorio centralizado de apoderados, jugadores, entrenadores y directiva |
| Sin reportes formales | Exportación a Excel, PDFs de comprobantes, reportes financieros por período |

---

## Stack Tecnológico

### Backend

| Tecnología | Rol |
|---|---|
| Node.js 20 + Express | Servidor HTTP / API REST |
| TypeORM + PostgreSQL 16 | Persistencia, migraciones versionadas |
| Passport.js + JWT | Autenticación stateless por roles |
| Socket.IO | Notificaciones en tiempo real |
| Nodemailer | Correos (comprobantes, recuperación de contraseña) |
| PDFKit + bwip-js | Generación de PDFs y barcodes Code 128 |
| Multer + AWS S3 | Subida de vouchers y multimedia |
| Joi | Validación estricta de esquemas de entrada |
| node-cron | Tareas programadas (limpieza de tokens, expiración) |
| Vitest + Supertest | Unit tests e integration tests |

### Frontend

| Tecnología | Rol |
|---|---|
| Flutter (Dart 3.7) | App multiplataforma — Android · iOS · Web |
| Socket.IO client | Notificaciones en tiempo real |
| FL Chart | Gráficos estadísticos de asistencia y finanzas |
| Flutter Secure Storage | Almacenamiento seguro de JWT |
| File Picker + Excel + spreadsheet_decoder | Importación masiva de datos desde planillas |
| flutter_local_notifications | Notificaciones push locales |

### Infraestructura

| Tecnología | Rol |
|---|---|
| Docker + docker-compose | Orquestación (postgres, backend, nginx) con healthchecks |
| Nginx Alpine | Reverse proxy, rate limiting, WebSocket upgrade, SPA serving |
| Cloudflare | HTTPS, WAF, CDN |
| GitHub Actions | 7 workflows de CI/CD |
| TruffleHog + CodeQL | Secrets scan + análisis estático de seguridad (SAST) |

---

## Roles y Funcionalidades

```
┌────────────────────────────────────────────────────────────────┐
│  ROL            ACCESOS PRINCIPALES                            │
├────────────────────────────────────────────────────────────────┤
│  Directiva    · Dashboard ejecutivo con métricas del club      │
│               · Gestión completa de usuarios y roles           │
│               · Inventario y kiosco · Actas de reunión         │
│               · Reportes financieros y de asistencia           │
├────────────────────────────────────────────────────────────────┤
│  Tesorera     · Validación de vouchers de pago                 │
│               · Control de cuotas y mensualidades              │
│               · Comprobantes electrónicos en PDF               │
│               · Vista consolidada de ventas del kiosco         │
├────────────────────────────────────────────────────────────────┤
│  Entrenador   · Apertura y cierre de sesiones de asistencia    │
│               · Justificantes y meses de exención              │
│               · Gestión de eventos deportivos y torneos        │
├────────────────────────────────────────────────────────────────┤
│  Apoderado    · Subida de vouchers de pago                     │
│               · Historial de pagos del jugador                 │
│               · Recepción de comprobantes validados            │
├────────────────────────────────────────────────────────────────┤
│  RamaExterna  · Gestión de torneos e inscripciones             │
│               · Coordinación de eventos deportivos externos    │
└────────────────────────────────────────────────────────────────┘
```

---

## Estructura del Repositorio

```
WesRugby/
├── .github/workflows/
│   ├── ci-backend.yml              # Lint + unit tests + integration tests
│   ├── ci-frontend.yml             # flutter analyze + flutter test
│   ├── deploy.yml                  # Tests → Build → SSH → Rollback
│   ├── pr-checks.yml               # Conventional commits + detección de secretos
│   ├── security-scan.yml           # npm audit · TruffleHog · CodeQL
│   ├── docker-build.yml
│   └── cron-backup.yml             # pg_dump diario 02:00 UTC
│
├── backend/
│   ├── src/
│   │   ├── controllers/            # 26 controladores
│   │   ├── entity/                 # 29 entidades TypeORM
│   │   ├── routes/                 # 27 módulos de rutas
│   │   ├── services/               # Lógica de negocio
│   │   ├── middlewares/            # JWT, roles, rate limit
│   │   ├── utils/                  # Barcodes, PDF, storage, email
│   │   └── config/                 # DB, env, initialSetup con seed
│   ├── migrations/                 # Migraciones versionadas de esquema
│   ├── tests/
│   │   ├── handlers/
│   │   ├── helpers/
│   │   ├── utils/
│   │   ├── validations/
│   │   └── integration/            # auth + inventory vs PostgreSQL real
│   ├── vitest.config.js
│   └── vitest.integration.config.js
│
├── frontend/
│   ├── lib/
│   │   ├── features/               # auth · admin · inventory · home
│   │   ├── core/                   # inyección de dependencias, router
│   │   ├── data/                   # repositorios y fuentes de datos
│   │   └── shared/                 # widgets y utilidades compartidas
│   └── test/                       # unit tests Dart
│
├── nginx/                          # nginx.conf + virtual host con WebSocket
├── docker-compose.yml              # Stack productivo
├── docker-compose.dev.yml          # Override para desarrollo local
└── backup.sh                       # Script de backup invocado por cron
```

---

## Correr el proyecto localmente

### Prerrequisitos

- Node.js 20+
- Flutter SDK 3.7+
- Docker y Docker Compose
- PostgreSQL 16 (o usar el contenedor)

### Backend

```bash
cd backend/
cp src/config/.env.example src/config/.env   # completar variables
npm install
npm run dev                                   # nodemon en puerto 3000
```

### Tests del backend

```bash
# Unit tests
npm test

# Integration tests (requiere PostgreSQL corriendo y variables de entorno configuradas)
npm run test:integration

# Todos juntos
npm run test:all
```

### Frontend

```bash
cd frontend/
flutter pub get
flutter run                  # Android / iOS
flutter run -d chrome        # Flutter Web
```

### Stack completo con Docker

```bash
cp backend/src/config/.env.example backend/src/config/.env   # completar
docker compose -f docker-compose.dev.yml up --build
```

La API quedará disponible en `http://localhost:3000/api` y el frontend en `http://localhost`.

### Generar hoja de barcodes para impresión

```bash
cd backend/
npm run print:sheet          # genera output/hoja_barcodes.pdf
```

---

## Autores

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/JoMULLOA">
        <img src="https://avatars.githubusercontent.com/JoMULLOA" width="80px" alt="José Manríquez"/><br/>
        <strong>José Manríquez</strong>
      </a><br/>
      Software Engineer
    </td>
    <td align="center">
      <a href="https://github.com/lu1spereir4">
        <img src="https://avatars.githubusercontent.com/lu1spereir4" width="80px" alt="Luis Pereira"/><br/>
        <strong>Luis Pereira</strong>
      </a><br/>
      Software Engineer
    </td>
  </tr>
</table>

---

<div align="center">

**Universidad del Bío-Bío · Facultad de Ciencias Empresariales**<br/>
**Ingeniería Civil en Informática · Proyecto de Título · 2025**

</div>

