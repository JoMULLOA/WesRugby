"use strict";
import { EntitySchema } from "typeorm";

const ActaReunionSchema = new EntitySchema({
  name: "ActaReunion",
  tableName: "actas_reunion",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    titulo: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Título del acta de reunión",
    },
    fecha: {
      type: "date",
      nullable: false,
      comment: "Fecha de la reunión",
    },
    horaInicio: {
      type: "time",
      nullable: true,
      comment: "Hora de inicio de la reunión",
    },
    horaFin: {
      type: "time",
      nullable: true,
      comment: "Hora de finalización de la reunión",
    },
    lugar: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Lugar donde se realizó la reunión",
    },
    descripcion: {
      type: "text",
      nullable: false,
      comment: "Descripción detallada de la reunión",
    },
    asistentes: {
      type: "text",
      nullable: true,
      comment: "Lista de asistentes a la reunión",
    },
    acuerdos: {
      type: "text",
      nullable: true,
      comment: "Acuerdos tomados en la reunión",
    },
    proximosCompromiso: {
      type: "text",
      nullable: true,
      comment: "Próximos compromisos y fechas",
    },
    estado: {
      type: "enum",
      enum: ["borrador", "publicada", "archivada"],
      default: "borrador",
      nullable: false,
      comment: "Estado del acta",
    },
    rutCreador: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó el acta (directiva)",
    },
    nombreCreador: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre completo del creador",
    },
    archivoAdjunto: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "URL del archivo adjunto si existe",
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
  indices: [
    {
      name: "IDX_ACTA_FECHA",
      columns: ["fecha"],
    },
    {
      name: "IDX_ACTA_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_ACTA_CREADOR",
      columns: ["rutCreador"],
    },
  ],
});

export default ActaReunionSchema;
