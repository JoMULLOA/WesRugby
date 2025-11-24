"use strict";
import { EntitySchema } from "typeorm";

const AsistenciaSchema = new EntitySchema({
  name: "Asistencia",
  tableName: "asistencias",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    // Referencias
    inscripcionId: {
      type: "uuid",
      nullable: false,
      comment: "ID de la inscripción del alumno",
    },
    eventoId: {
      type: "uuid",
      nullable: true,
      comment: "ID del evento deportivo (opcional)",
    },
    // Información de la Asistencia
    fecha: {
      type: "date",
      nullable: false,
      comment: "Fecha de la asistencia",
    },
    tipoActividad: {
      type: "enum",
      enum: ["entrenamiento", "partido", "evento", "reunion", "torneo", "otro"],
      nullable: false,
      comment: "Tipo de actividad",
    },
    categoria: {
      type: "varchar",
      length: 50,
      nullable: true,
      comment: "Categoría o grupo (infantil, juvenil, senior, etc)",
    },
    horaInicio: {
      type: "time",
      nullable: false,
      comment: "Hora de inicio de la actividad",
    },
    horaFin: {
      type: "time",
      nullable: true,
      comment: "Hora de fin de la actividad",
    },
    // Estado de Asistencia
    estado: {
      type: "enum",
      enum: ["presente", "ausente", "tardanza", "justificado", "suspendido"],
      nullable: false,
      comment: "Estado de la asistencia",
    },
    horaLlegada: {
      type: "time",
      nullable: true,
      comment: "Hora real de llegada del alumno",
    },
    horaSalida: {
      type: "time",
      nullable: true,
      comment: "Hora real de salida del alumno",
    },
    // Información Adicional
    lugar: {
      type: "varchar",
      length: 200,
      nullable: true,
      comment: "Lugar donde se realizó la actividad",
    },
    clima: {
      type: "enum",
      enum: ["soleado", "nublado", "lluvia", "viento", "frio", "caluroso"],
      nullable: true,
      comment: "Condiciones climáticas",
    },
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones sobre la asistencia o comportamiento",
    },
    justificacion: {
      type: "text",
      nullable: true,
      comment: "Justificación en caso de ausencia o tardanza",
    },
    apoderadoEmailJustificacion: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Correo del apoderado que subió la justificación",
    },
    // Archivo de Justificación (opcional)
    rutaJustificacion: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Ruta del archivo de justificante (S3 o relativo)",
    },
    nombreArchivoJustificacion: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Nombre original del archivo de justificante",
    },
    tipoArchivoJustificacion: {
      type: "varchar",
      length: 50,
      nullable: true,
      comment: "Tipo MIME del archivo de justificante",
    },
    tamanoArchivoJustificacion: {
      type: "int",
      nullable: true,
      comment: "Tamaño del archivo de justificante en bytes",
    },
    // Rendimiento (opcional)
    calificacion: {
      type: "enum",
      enum: ["excelente", "muy_bueno", "bueno", "regular", "necesita_mejorar"],
      nullable: true,
      comment: "Calificación del rendimiento en la sesión",
    },
    lesiones: {
      type: "text",
      nullable: true,
      comment: "Registro de lesiones o problemas físicos",
    },
    // Registro de Quien Marca Asistencia
    marcadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del entrenador/responsable que marcó la asistencia",
    },
    fechaRegistro: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
      comment: "Cuándo se registró la asistencia",
    },
    // Validación de Apoderado
    validadoPorApoderado: {
      type: "boolean",
      default: false,
      comment: "Si el apoderado validó/vio esta asistencia",
    },
    fechaValidacionApoderado: {
      type: "timestamp with time zone",
      nullable: true,
    },
    // Metadatos
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
    inscripcion: {
      type: "many-to-one",
      target: "Inscripcion",
      joinColumn: { name: "inscripcionId" },
      onDelete: "CASCADE",
    },
    evento: {
      type: "many-to-one",
      target: "EventoDeportivo",
      joinColumn: { name: "eventoId" },
      nullable: true,
    },
    marcadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "marcadoPorRut", referencedColumnName: "rut" },
    },
  },
  indices: [
    {
      name: "IDX_ASISTENCIA_FECHA",
      columns: ["fecha"],
    },
    {
      name: "IDX_ASISTENCIA_INSCRIPCION",
      columns: ["inscripcionId"],
    },
    {
      name: "IDX_ASISTENCIA_TIPO",
      columns: ["tipoActividad"],
    },
    {
      name: "IDX_ASISTENCIA_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_ASISTENCIA_CATEGORIA",
      columns: ["categoria"],
    },
    {
      name: "IDX_ASISTENCIA_MARCADO_POR",
      columns: ["marcadoPorRut"],
    },
    {
      name: "IDX_ASISTENCIA_FECHA_TIPO",
      columns: ["fecha", "tipoActividad"],
    },
  ],
});

export default AsistenciaSchema;
