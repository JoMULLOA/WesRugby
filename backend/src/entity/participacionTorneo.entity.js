"use strict";
import { EntitySchema } from "typeorm";

const ParticipacionTorneoSchema = new EntitySchema({
  name: "ParticipacionTorneo",
  tableName: "participaciones_torneo",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    torneoId: {
      type: "int",
      nullable: false,
      comment: "ID del torneo",
    },
    rutCoordinador: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del coordinador de rama que participa",
    },
    nombreRama: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre de la rama deportiva",
    },
    categoria: {
      type: "enum",
      enum: ["sub-8", "sub-10", "sub-12", "sub-14"],
      nullable: false,
      comment: "Categoría en la que participan",
    },
    cantidadNinos: {
      type: "int",
      nullable: false,
      default: 0,
      comment: "Cantidad de niños que jugarán",
    },
    cantidadInvitados: {
      type: "int",
      nullable: false,
      default: 0,
      comment: "Cantidad de invitados (niños que no jugarán o representantes)",
    },
    detalleInvitados: {
      type: "json",
      nullable: true,
      comment: "Detalle de los invitados (nombres, colegios, etc.)",
    },
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones adicionales",
    },
    estado: {
      type: "enum",
      enum: ["confirmado", "pendiente", "cancelado"],
      default: "confirmado",
      nullable: false,
      comment: "Estado de la participación",
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
    torneo: {
      type: "many-to-one",
      target: "Torneo",
      joinColumn: { name: "torneoId", referencedColumnName: "id" },
      onDelete: "CASCADE",
    },
    coordinador: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "rutCoordinador", referencedColumnName: "rut" },
    },
  },
  indices: [
    {
      name: "IDX_PARTICIPACION_TORNEO",
      columns: ["torneoId"],
    },
    {
      name: "IDX_PARTICIPACION_COORDINADOR",
      columns: ["rutCoordinador"],
    },
    {
      name: "IDX_PARTICIPACION_CATEGORIA",
      columns: ["categoria"],
    },
    {
      name: "IDX_PARTICIPACION_UNICA",
      columns: ["torneoId", "rutCoordinador", "categoria"],
      unique: true,
    },
  ],
});

export default ParticipacionTorneoSchema;
