"use strict";
import { EntitySchema } from "typeorm";

const TorneoSchema = new EntitySchema({
  name: "Torneo",
  tableName: "torneos",
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
      comment: "Nombre del torneo",
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción del torneo",
    },
    fechaTorneo: {
      type: "date",
      nullable: false,
      comment: "Fecha en que se realizará el torneo",
    },
    lugar: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Lugar donde se realizará el torneo",
    },
    categorias: {
      type: "json", // ["sub-8", "sub-10", "sub-12", "sub-14"]
      nullable: false,
      default: "[]",
      comment: "Categorías disponibles para el torneo",
    },
    estado: {
      type: "enum",
      enum: ["abierto", "cerrado", "finalizado", "cancelado"],
      default: "abierto",
      nullable: false,
      comment: "Estado del torneo",
    },
    rutCreador: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó el torneo",
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
    creador: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "rutCreador", referencedColumnName: "rut" },
    },
    participaciones: {
      type: "one-to-many",
      target: "ParticipacionTorneo",
      inverseSide: "torneo",
    },
  },
  indices: [
    {
      name: "IDX_TORNEO_FECHA",
      columns: ["fechaTorneo"],
    },
    {
      name: "IDX_TORNEO_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_TORNEO_CREADOR",
      columns: ["rutCreador"],
    },
  ],
});

export default TorneoSchema;
