# WesRugby - Club de Rugby Wessex
**Sistema de Gestión Integral para Club de Rugby**

Proyecto desarrollado para proyecto de título en el año 2025, Universidad del Bío Bío.

## 📋 Descripción del Proyecto

WesRugby es una aplicación móvil diseñada específicamente para la gestión integral del Club de Rugby Wessex. El sistema permite la administración de pagos, control de asistencias, comunicación entre roles y gestión administrativa del club.

## 🚀 Características Principales

- **Sistema de Roles**: Directiva, Tesorera, Entrenador, Apoderado
- **Gestión de Pagos**: Subida de vouchers y comprobantes electrónicos
- **Control de Asistencias**: Registro y seguimiento de entrenamientos
- **Panel Administrativo**: Dashboards específicos para cada rol
- **Notificaciones**: Sistema de comunicación en tiempo real
- **Reportes**: Estadísticas y análisis del club

## 🛠️ Arquitectura Tecnológica

### Frontend
- **Flutter**: Framework multiplataforma para desarrollo móvil
- **Dart**: Lenguaje de programación principal
- **Material Design**: Sistema de diseño para UI/UX consistente

### Backend
- **Node.js**: Runtime de JavaScript del lado servidor
- **Express.js**: Framework web minimalista y flexible
- **TypeORM**: ORM para manejo de entidades y relaciones
- **JWT**: Autenticación basada en tokens
- **Nodemailer**: Sistema de envío de correos electrónicos

### Base de Datos
- **PostgreSQL**: Sistema de gestión de base de datos relacional
- **Migraciones**: Control de versiones de esquema de BD

### DevOps y Deployment
- **Git**: Control de versiones
- **GitHub**: Repositorio y colaboración

## 📱 Funcionalidades por Rol

### Directiva
- Dashboard ejecutivo con métricas del club
- Gestión de usuarios y roles
- Reportes financieros y de asistencia

### Tesorera
- Control de pagos y cuotas
- Validación de vouchers
- Reportes financieros detallados

### Entrenador
- Registro de asistencias
- Gestión de entrenamientos
- Control de jugadores

### Apoderado
- Subida de vouchers de pago
- Consulta de historial de pagos
- Recepción de comprobantes electrónicos

## 🏗️ Estructura del Proyecto

```
WesRugby/
├── backend/                 # Servidor Node.js + Express
│   ├── src/
│   │   ├── controllers/     # Lógica de controladores
│   │   ├── entity/          # Modelos de base de datos
│   │   ├── routes/          # Definición de rutas API
│   │   ├── services/        # Lógica de negocio
│   │   ├── middlewares/     # Middlewares personalizados
│   │   ├── config/          # Configuraciones del sistema
│   │   └── utils/           # Utilidades generales
│   └── package.json         # Dependencias backend
│
├── frontend/                # Aplicación Flutter
│   ├── lib/
│   │   ├── admin/           # Dashboards administrativos
│   │   ├── auth/            # Módulo de autenticación
│   │   ├── services/        # Servicios API
│   │   ├── widgets/         # Componentes reutilizables
│   │   └── config/          # Configuraciones
│   └── pubspec.yaml         # Dependencias Flutter
│
└── README.md                # Documentación del proyecto
```

## 🔧 Configuración y Desarrollo

### Prerrequisitos
- **Node.js** (v16 o superior)
- **Flutter SDK** (v3.0 o superior)
- **PostgreSQL** (v12 o superior)
- **Android Studio** y **VS Code**
- **Git** para control de versiones

### Instalación Backend
```bash
cd backend/
npm install
npm run dev
```

### Instalación Frontend
```bash
cd frontend/
flutter pub get
flutter run
```

**Universidad del Bío Bío - Facultad de Ciencias Empresariales** 
**Proyecto de Título** 
**Ingeniería Civil en Informática - 2025**

---

## 🏅 Roles y Responsabilidades

<table>
  <tr>
    <th>Foto</th>
    <th>Integrante</th>
    <th>Rol Principal</th>
    <th>Especialización</th>
    <th>Contribuciones Clave</th>
  </tr>
  <tr>
    <td align="center">
      <img src="https://avatars.githubusercontent.com/JoMULLOA" width="60px;" alt="JoMULLOA"/>
    </td>
    <td><a href="https://github.com/JoMULLOA"><strong>José Manríquez</strong></a></td>
    <td>Software Engineer</td>
    <td>Análisis, evaluación y desarrollo del proyecto</td>
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
    <td>Análisis, evaluación y desarrollo del proyecto</td>
    <td>
      Desarrollo de informe de proyecto
    </td>
  </tr>
</table>