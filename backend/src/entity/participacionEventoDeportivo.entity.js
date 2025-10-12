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
      type: "enum",
      enum: ["sub-8", "sub-9", "sub-10", "sub-11", "sub-12", "sub-13", "sub-14", "sub-15", "sub-16", "sub-17", "sub-18", "sub-19", "senior", "veteranos"],
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