"use strict";
import { EntitySchema } from "typeorm";

const EstudianteSchema = new EntitySchema({
  name: "Estudiante",
  tableName: "estudiantes",
  columns: {
    rut: {
      type: "varchar",
      length: 12,
      primary: true,
      nullable: false,
      unique: true,
    },
    nombre: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    categoria: {
      type: "varchar",
      length: 10,
      nullable: true,
    },
    ficha: {
      type: "boolean",
      nullable: true,
    },
    curso: {
      type: "varchar",
      length: 10,
      nullable: false,
    },
    fechaNacimiento: {
      type: "date",
      nullable: true,
    },
    correoApoderadoGenerado: {
      type: "varchar",
      length: 255,
      nullable: true,
      unique: true,
      comment: "Correo institucional generado para el apoderado",
    },
    telefono: {
      type: "varchar",
      length: 20,
      nullable: true,
    },
    direccion: {
      type: "text",
      nullable: true,
    },
    email: {
      type: "varchar",
      length: 255,
      nullable: true,
      unique: true,
    },
    nombreMadre: {
      type: "varchar",
      length: 120,
      nullable: true,
    },
    telefonoMadre: {
      type: "varchar",
      length: 15,
      nullable: true,
    },
    emailMadre: {
      type: "varchar",
      length: 255,
      nullable: true,
    },
    nombrePadre: {
      type: "varchar",
      length: 120,
      nullable: true,
    },
    telefonoPadre: {
      type: "varchar",
      length: 15,
      nullable: true,
    },
    emailPadre: {
      type: "varchar",
      length: 255,
      nullable: true,
    },
    hermanos: {
      type: "jsonb",
      nullable: true,
      comment: "Lista de RUTs asociados como hermanos",
    },
    enfermedad: {
      type: "text",
      nullable: true,
    },
    talla: {
      type: "varchar",
      length: 5,
      nullable: true,
    },
    dorsalNombre: {
      type: "varchar",
      length: 120,
      nullable: true,
    },
    alumnoNuevo: {
      type: "varchar",
      length: 50,
      nullable: true,
    },
    asistencia: {
      type: "varchar",
      length: 50,
      nullable: true,
    },
    pagos: {
      type: "jsonb",
      nullable: true,
      comment: "Información de matrícula, mensualidades y total anual",
    },
    equipamiento: {
      type: "jsonb",
      nullable: true,
      comment: "Registro de poleron, calcetas, protector bucal, uniforme y añadidos",
    },
    contactoEmergencia: {
      type: "varchar",
      length: 100,
      nullable: true,
    },
    telefonoEmergencia: {
      type: "varchar",
      length: 20,
      nullable: true,
    },
    rutResponsable: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT del apoderado principal"
    },
    nombreResponsable: {
      type: "varchar",
      length: 255,
      nullable: true,
    },
    rutResponsable2: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT del apoderado secundario"
    },
    nombreResponsable2: {
      type: "varchar",
      length: 255,
      nullable: true,
    },
    fotoUrl: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "URL de la foto del estudiante"
    },
    observaciones: {
      type: "text",
      nullable: true,
    },
    estado: {
      type: "enum",
      enum: ["activo", "inactivo", "suspendido"],
      default: "activo",
      nullable: false,
    },
    createdAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
    updatedAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      onUpdate: "CURRENT_TIMESTAMP",
      nullable: false,
    },
  },
  // Removemos las relaciones por ahora para evitar problemas de clave foránea
  // Las relaciones se pueden manejar manualmente en los servicios
  indices: [
    {
      name: "IDX_ESTUDIANTE_RUT",
      columns: ["rut"],
      unique: true,
    },
    {
      name: "IDX_ESTUDIANTE_RESPONSABLE",
      columns: ["rutResponsable"],
    },
    {
      name: "IDX_ESTUDIANTE_RESPONSABLE2", 
      columns: ["rutResponsable2"],
    },
    {
      name: "IDX_ESTUDIANTE_CURSO",
      columns: ["curso"],
    },
    {
      name: "IDX_ESTUDIANTE_CATEGORIA",
      columns: ["categoria"],
    },
    {
      name: "IDX_ESTUDIANTE_FICHA",
      columns: ["ficha"],
    },
  ],
});

export default EstudianteSchema;