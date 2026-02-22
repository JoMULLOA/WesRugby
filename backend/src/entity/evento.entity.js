"use strict";
import { EntitySchema } from "typeorm";

const EventoSchema = new EntitySchema({
  name: "Evento",
  tableName: "eventos",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    nombre: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    fecha: {
      type: "date",
      nullable: false,
    },
    descripcion: {
      type: "text",
      nullable: true,
    },
    estado: {
      type: "enum",
      enum: ["activo", "finalizado", "cancelado"],
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
  relations: {
    participaciones: {
      type: "one-to-many",
      target: "ParticipacionEvento",
      inverseSide: "evento",
    },
  },
});

export default EventoSchema;
