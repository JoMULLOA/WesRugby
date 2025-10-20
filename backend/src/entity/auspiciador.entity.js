"use strict";
import { EntitySchema } from "typeorm";

const AuspiciadorSchema = new EntitySchema({
  name: "Auspiciador",
  tableName: "auspiciadores",
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
      comment: "Nombre del auspiciador"
    },
    imagen: {
      type: "varchar",
      length: 500,
      nullable: false,
      comment: "URL del logo del auspiciador"
    },
    sitioWeb: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "URL del sitio web del auspiciador"
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción del auspiciador"
    },
    estado: {
      type: "enum",
      enum: ["activo", "inactivo"],
      default: "activo",
      nullable: false,
      comment: "Estado del auspiciador"
    },
    rutCreador: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó el auspiciador (directiva)"
    },
    nombreCreador: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre completo del creador"
    },
    orden: {
      type: "int",
      default: 0,
      nullable: false,
      comment: "Orden de visualización en el home"
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
      name: "IDX_AUSPICIADOR_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_AUSPICIADOR_ORDEN",
      columns: ["orden"],
    },
  ],
});

export default AuspiciadorSchema;