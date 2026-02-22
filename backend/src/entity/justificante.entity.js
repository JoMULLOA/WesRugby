"use strict";
import { EntitySchema } from "typeorm";

const JustificanteSchema = new EntitySchema({
  name: "Justificante",
  tableName: "justificantes",
  columns: {
    id: { type: "uuid", primary: true, generated: "uuid" },
    apoderadoRut: { type: "varchar", length: 12, nullable: false },
    apoderadoEmail: { type: "varchar", length: 255, nullable: true },
    estudianteRut: { type: "varchar", length: 12, nullable: false },
    fechaInicio: { type: "date", nullable: false },
    fechaFin: { type: "date", nullable: true },
    tipo: { type: "varchar", length: 30, nullable: false },
    motivo: { type: "text", nullable: false },
    descripcion: { type: "text", nullable: true },
    rutaArchivo: { type: "varchar", length: 500, nullable: true },
    nombreArchivoOriginal: { type: "varchar", length: 255, nullable: true },
    tipoArchivo: { type: "varchar", length: 50, nullable: true },
    tamanoArchivo: { type: "int", nullable: true },
    estado: {
      type: "varchar",
      length: 20,
      default: "pendiente",
      nullable: false,
    },
    motivoRechazo: { type: "text", nullable: true },
    observacionesDirectiva: { type: "text", nullable: true },
    revisadoPorRut: { type: "varchar", length: 12, nullable: true },
    fechaRevision: { type: "timestamp with time zone", nullable: true },
    // Meses de exención de pago asociados (array de strings YYYY-MM)
    mesesExencion: { type: "jsonb", nullable: true },
    fechaSubida: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
    },
    createdAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
    },
    updatedAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      onUpdate: "CURRENT_TIMESTAMP",
    },
  },
  indices: [
    { name: "IDX_JUSTIFICANTE_APODERADO", columns: ["apoderadoRut"] },
    { name: "IDX_JUSTIFICANTE_ESTUDIANTE", columns: ["estudianteRut"] },
    { name: "IDX_JUSTIFICANTE_ESTADO", columns: ["estado"] },
    { name: "IDX_JUSTIFICANTE_FECHA_INICIO", columns: ["fechaInicio"] },
    { name: "IDX_JUSTIFICANTE_FECHA_FIN", columns: ["fechaFin"] },
  ],
});

export default JustificanteSchema;
