# WesRugby - Club de Rugby Wessex
**Sistema de GestiÃ³n Integral para Club de Rugby**

Proyecto desarrollado para proyecto de tÃ­tulo en el aÃ±o 2025, Universidad del BÃ­o BÃ­o.

## ðŸ“‹ DescripciÃ³n del Proyecto

WesRugby es una aplicaciÃ³n mÃ³vil diseÃ±ada especÃ­ficamente para la gestiÃ³n integral del Club de Rugby Wessex. El sistema permite la administraciÃ³n de pagos, control de asistencias, comunicaciÃ³n entre roles y gestiÃ³n administrativa del club.

## ðŸš€ CaracterÃ­sticas Principales

- **Sistema de Roles**: Directiva, Tesorera, Entrenador, Apoderado
- **GestiÃ³n de Pagos**: Subida de vouchers y comprobantes electrÃ³nicos
- **Control de Asistencias**: Registro y seguimiento de entrenamientos
- **Panel Administrativo**: Dashboards especÃ­ficos para cada rol
- **Notificaciones**: Sistema de comunicaciÃ³n en tiempo real
- **Reportes**: EstadÃ­sticas y anÃ¡lisis del club

## ðŸ› ï¸ Arquitectura TecnolÃ³gica

### Frontend
- **Flutter**: Framework multiplataforma para desarrollo mÃ³vil
- **Dart**: Lenguaje de programaciÃ³n principal
- **Material Design**: Sistema de diseÃ±o para UI/UX consistente

### Backend
- **Node.js**: Runtime de JavaScript del lado servidor
- **Express.js**: Framework web minimalista y flexible
- **TypeORM**: ORM para manejo de entidades y relaciones
- **JWT**: AutenticaciÃ³n basada en tokens
- **Nodemailer**: Sistema de envÃ­o de correos electrÃ³nicos

### Base de Datos
- **PostgreSQL**: Sistema de gestiÃ³n de base de datos relacional
- **Migraciones**: Control de versiones de esquema de BD

### DevOps y Deployment
- **Git**: Control de versiones
- **GitHub**: Repositorio y colaboraciÃ³n

## ðŸ“± Funcionalidades por Rol

### Directiva
- Dashboard ejecutivo con mÃ©tricas del club
- GestiÃ³n de usuarios y roles
- Reportes financieros y de asistencia

### Tesorera
- Control de pagos y cuotas
- ValidaciÃ³n de vouchers
- Reportes financieros detallados

### Entrenador
- Registro de asistencias
- GestiÃ³n de entrenamientos
- Control de jugadores

### Apoderado
- Subida de vouchers de pago
- Consulta de historial de pagos
- RecepciÃ³n de comprobantes electrÃ³nicos

## ðŸ—ï¸ Estructura del Proyecto

```
WesRugby/
â”œâ”€â”€ backend/                 # Servidor Node.js + Express
â”‚   â”œâ”€â”€ src/
â”‚   â”‚   â”œâ”€â”€ controllers/     # LÃ³gica de controladores
â”‚   â”‚   â”œâ”€â”€ entity/          # Modelos de base de datos
â”‚   â”‚   â”œâ”€â”€ routes/          # DefiniciÃ³n de rutas API
â”‚   â”‚   â”œâ”€â”€ services/        # LÃ³gica de negocio
â”‚   â”‚   â”œâ”€â”€ middlewares/     # Middlewares personalizados
â”‚   â”‚   â”œâ”€â”€ config/          # Configuraciones del sistema
â”‚   â”‚   â””â”€â”€ utils/           # Utilidades generales
â”‚   â””â”€â”€ package.json         # Dependencias backend
â”‚
â”œâ”€â”€ frontend/                # AplicaciÃ³n Flutter
â”‚   â”œâ”€â”€ lib/
â”‚   â”‚   â”œâ”€â”€ admin/           # Dashboards administrativos
â”‚   â”‚   â”œâ”€â”€ auth/            # MÃ³dulo de autenticaciÃ³n
â”‚   â”‚   â”œâ”€â”€ services/        # Servicios API
â”‚   â”‚   â”œâ”€â”€ widgets/         # Componentes reutilizables
â”‚   â”‚   â””â”€â”€ config/          # Configuraciones
â”‚   â””â”€â”€ pubspec.yaml         # Dependencias Flutter
â”‚
â””â”€â”€ README.md                # DocumentaciÃ³n del proyecto
```

## Inventario y kiosco

- Backend expone /api/inventario/... para productos, ventas y generacion de PDFs.
- Ejecuta `npm run print:sheet` desde `backend/` para crear la hoja `output/hoja_barcodes.pdf`.
- En Flutter abre la ruta `/inventario/simulador` para probar el lector y registrar ventas variables.

## ðŸ”§ ConfiguraciÃ³n y Desarrollo

### Prerrequisitos
- **Node.js** (v16 o superior)
- **Flutter SDK** (v3.0 o superior)
- **PostgreSQL** (v12 o superior)
- **Android Studio** y **VS Code**
- **Git** para control de versiones

### InstalaciÃ³n Backend
```bash
cd backend/
npm install
npm run dev
```

### InstalaciÃ³n Frontend
```bash
cd frontend/
flutter pub get
flutter run
```

**Universidad del BÃ­o BÃ­o - Facultad de Ciencias Empresariales** 
**Proyecto de TÃ­tulo** 
**IngenierÃ­a Civil en InformÃ¡tica - 2025**

---

## ðŸ… Roles y Responsabilidades

<table>
  <tr>
    <th>Foto</th>
    <th>Integrante</th>
    <th>Rol Principal</th>
    <th>EspecializaciÃ³n</th>
    <th>Contribuciones Clave</th>
  </tr>
  <tr>
    <td align="center">
      <img src="https://avatars.githubusercontent.com/JoMULLOA" width="60px;" alt="JoMULLOA"/>
    </td>
    <td><a href="https://github.com/JoMULLOA"><strong>JosÃ© ManrÃ­quez</strong></a></td>
    <td>Software Engineer</td>
    <td>AnÃ¡lisis, evaluaciÃ³n y desarrollo del proyecto</td>
    <td>
      Desarrollo de informe de proyecto, login/logout
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://avatars.githubusercontent.com/lu1spereir4" width="60px;" alt="lu1spereir4"/>
    </td>
    <td><a href="https://github.com/lu1spereir4"><strong>Luis Pereira</strong></a></td>
    <td>Software Engineer</td>
    <td>AnÃ¡lisis, evaluaciÃ³n y desarrollo del proyecto</td>
    <td>
      Desarrollo de informe de proyecto
    </td>
  </tr>
</table>
