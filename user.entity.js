import { EntitySchema } from "typeorm";

const UserSchema = new EntitySchema({
  name: "User",
  tableName: "users",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    rut: {
      type: "varchar",
      length: 12,
      nullable: false,
      unique: true,
    },
    nombreCompleto: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    fechaNacimiento: {
      type: "date",
      nullable: true,
    },
    genero: {
      type: "enum",
      enum: ["masculino", "femenino", "no_binario", "prefiero_no_decir"],
      nullable: false,
    },
    carrera: {
      type: "varchar",
      length: 100,
      nullable: true,
    },
    telefono: {
      type: "varchar",
      length: 20,
      nullable: true,
    },
    altura: {
      type: "int",
      nullable: true,
    },
    peso: {
      type: "int",
      nullable: true,
    },
    descripcion: {
      type: "text",
      nullable: true,
    },
    clasificacion: {
      type: "float",
      nullable: true,
    },
    cantidadValoraciones: {
      type: "int",
      nullable: false,
      default: 0,
    },
    puntuacion: {
      type: "int",
      nullable: true,
    },
    contadorReportes: {
      type: "int",
      nullable: false,
      default: 0,
    },
    email: {
      type: "varchar",
      length: 255,
      nullable: false,
      unique: true,
    },
    rol: {
      type: "enum",
      enum: ["directiva", "tesorera", "apoderado", "entrenador", "administrador"],
      nullable: false,
    },
    password: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    fcmToken: {
      type: "text",
      nullable: true,
    },
    saldo: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      default: 0,
    },
    tarjetas: {
      type: "jsonb",
      nullable: true,
    },
    estado: {
      type: "enum",
      enum: ["activo", "inactivo", "bloqueado"],
      default: "activo",
      nullable: false,
    },
    createdAt: {
      type: "timestamp with time zone",
      createDate: true,
    },
    updatedAt: {
      type: "timestamp with time zone",
      updateDate: true,
    },
    deletedAt: {
      type: "timestamp with time zone",
      deleteDate: true,
      nullable: true,
    },
  },
  indices: [
    { name: "IDX_USERS_RUT", columns: ["rut"], unique: true },
    { name: "IDX_USERS_EMAIL", columns: ["email"], unique: true },
    { name: "IDX_USERS_ROL", columns: ["rol"] },
    { name: "IDX_USERS_ESTADO", columns: ["estado"] },
  ],
  relations: {
    players: {
      type: "one-to-many",
      target: "Player",
      inverseSide: "guardian",
    },
    createdEnrollments: {
      type: "one-to-many",
      target: "Enrollment",
      inverseSide: "createdBy",
    },
    approvedEnrollments: {
      type: "one-to-many",
      target: "Enrollment",
      inverseSide: "approvedBy",
    },
    submittedPayments: {
      type: "one-to-many",
      target: "Payment",
      inverseSide: "submittedBy",
    },
    reviewedPayments: {
      type: "one-to-many",
      target: "Payment",
      inverseSide: "reviewedBy",
    },
    attendanceRecords: {
      type: "one-to-many",
      target: "AttendanceRecord",
      inverseSide: "recordedBy",
    },
    notifications: {
      type: "one-to-many",
      target: "Notification",
      inverseSide: "recipient",
    },
    sales: {
      type: "one-to-many",
      target: "InventorySale",
      inverseSide: "soldBy",
    },
  },
});

export default UserSchema;