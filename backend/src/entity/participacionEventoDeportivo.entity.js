"use strict";
import { EntitySchema } from "typeorm";

const ParticipacionEventoDeportivoSchema = new EntitySchema({
  name: "ParticipacionEventoDeportivo",
  tableName: "participaciones_evento_deportivo",
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
    eventoDeportivoId: {
      type: "uuid",
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
    eventoDeportivo: {
      type: "many-to-one",
      target: "EventoDeportivo",
      joinColumn: {
        name: "eventoDeportivoId",
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

export default ParticipacionEventoDeportivoSchema;