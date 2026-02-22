"use strict";
import { EntitySchema } from "typeorm";

const ParticipacionEventoSchema = new EntitySchema({
  name: "ParticipacionEvento",
  tableName: "participaciones_evento",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    rutRamaExterna: {
      type: "varchar",
      length: 12,
      nullable: false,
    },
    eventoId: {
      type: "int",
      nullable: false,
    },
    cantidadNinos: {
      type: "int",
      nullable: false,
      default: 0,
    },
    categoria: {
      type: "varchar",
      length: 50,
      nullable: false,
    },
    listaInvitados: {
      type: "text",
      nullable: true,
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
    evento: {
      type: "many-to-one",
      target: "Evento",
      joinColumn: {
        name: "eventoId",
      },
    },
    ramaExterna: {
      type: "many-to-one",
      target: "User",
      joinColumn: {
        name: "rutRamaExterna",
        referencedColumnName: "rut",
      },
    },
  },
});

export default ParticipacionEventoSchema;
