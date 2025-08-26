"use strict";
import { EntitySchema } from "typeorm";

const InscripcionSchema = new EntitySchema({
  name: "Inscripcion",
  tableName: "inscripciones",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    codigoAlumno: {
      type: "varchar",
      length: 20,
      nullable: false,
      unique: true,
      comment: "Código único del alumno (ej: WR2024001)",
    },
    // Datos Personales del Alumno
    nombre: {
      type: "varchar",
      length: 100,
      nullable: false,
    },
    apellidos: {
      type: "varchar", 
      length: 100,
      nullable: false,
    },
    rutAlumno: {
      type: "varchar",
      length: 12,
      nullable: false,
      unique: true,
    },
    fechaNacimiento: {
      type: "date",
      nullable: false,
    },
    genero: {
      type: "enum",
      enum: ["masculino", "femenino", "no_binario", "prefiero_no_decir"],
      nullable: false,
    },
    direccion: {
      type: "text",
      nullable: true,
    },
    telefono: {
      type: "varchar",
      length: 15,
      nullable: true,
    },
    email: {
      type: "varchar",
      length: 255,
      nullable: true,
    },
    // Contacto de Emergencia
    contactoEmergencia: {
      type: "varchar",
      length: 100,
      nullable: false,
    },
    telefonoEmergencia: {
      type: "varchar",
      length: 15,
      nullable: false,
    },
    // Datos del Tutor/Apoderado
    nombreTutor: {
      type: "varchar",
      length: 100,
      nullable: false,
    },
    rutTutor: {
      type: "varchar",
      length: 12,
      nullable: false,
    },
    telefonoTutor: {
      type: "varchar",
      length: 15,
      nullable: false,
    },
    emailTutor: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    relacionAlumno: {
      type: "enum",
      enum: ["padre", "madre", "abuelo", "abuela", "tio", "tia", "tutor_legal", "otro"],
      nullable: false,
    },
    // Información Médica
    problemasSalud: {
      type: "text",
      nullable: true,
      comment: "Problemas de salud, medicamentos, alergias, etc.",
    },
    autorizacionMedica: {
      type: "boolean",
      default: false,
      comment: "Autorización para atención médica de emergencia",
    },
    // Estado y Gestión
    estado: {
      type: "enum",
      enum: ["pendiente", "activo", "inactivo", "baja", "suspendido"],
      default: "pendiente",
      nullable: false,
    },
    fechaInscripcion: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
    fechaAprobacion: {
      type: "timestamp with time zone",
      nullable: true,
    },
    fechaBaja: {
      type: "timestamp with time zone",
      nullable: true,
    },
    motivoBaja: {
      type: "text",
      nullable: true,
    },
    // Referencias
    planPagoId: {
      type: "uuid",
      nullable: true,
    },
    creadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó la inscripción",
    },
    aprobadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT del usuario que aprobó la inscripción",
    },
    // Información Adicional
    observaciones: {
      type: "text",
      nullable: true,
    },
    documentosRequeridos: {
      type: "jsonb",
      nullable: true,
      comment: "Lista de documentos requeridos y su estado",
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
  relations: {
    planPago: {
      type: "many-to-one",
      target: "PlanPago",
      joinColumn: { name: "planPagoId" },
      nullable: true,
    },
    creadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "creadoPorRut", referencedColumnName: "rut" },
    },
    aprobadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "aprobadoPorRut", referencedColumnName: "rut" },
      nullable: true,
    },
    asistencias: {
      type: "one-to-many",
      target: "Asistencia",
      inverseSide: "alumno",
    },
    pagos: {
      type: "one-to-many", 
      target: "ComprobantePago",
      inverseSide: "inscripcion",
    },
  },
  indices: [
    {
      name: "IDX_INSCRIPCION_CODIGO",
      columns: ["codigoAlumno"],
      unique: true,
    },
    {
      name: "IDX_INSCRIPCION_RUT_ALUMNO",
      columns: ["rutAlumno"],
      unique: true,
    },
    {
      name: "IDX_INSCRIPCION_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_INSCRIPCION_RUT_TUTOR",
      columns: ["rutTutor"],
    },
  ],
});

export default InscripcionSchema;
