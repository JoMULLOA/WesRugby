"use strict";
import { EntitySchema } from "typeorm";

const EventoMultimediaSchema = new EntitySchema({
  name: "EventoMultimedia",
  tableName: "eventos_multimedia",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    eventoDeportivoId: {
      type: "uuid",
      nullable: true,
    },
    eventoId: {
      type: "int",
      nullable: true,
    },
    tituloEvento: {
      type: "varchar",
      length: 200,
      nullable: false,
    },
    uploadedByRut: {
      type: "varchar",
      length: 12,
      nullable: false,
    },
    uploadedByNombre: {
      type: "varchar",
      length: 200,
      nullable: true,
    },
    uploadedByRol: {
      type: "varchar",
      length: 32,
      nullable: false,
    },
    fileName: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    originalName: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    mimeType: {
      type: "varchar",
      length: 100,
      nullable: false,
    },
    size: {
      type: "int",
      nullable: false,
    },
    extension: {
      type: "varchar",
      length: 16,
      nullable: true,
    },
    isPrivate: {
      type: "boolean",
      default: false,
    },
    sharedWithRamas: {
      type: "boolean",
      default: true,
    },
    storagePath: {
      type: "varchar",
      length: 400,
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
    eventoDeportivo: {
      type: "many-to-one",
      target: "EventoDeportivo",
      joinColumn: {
        name: "eventoDeportivoId",
      },
      nullable: true,
      onDelete: "CASCADE",
    },
    evento: {
      type: "many-to-one",
      target: "Evento",
      joinColumn: {
        name: "eventoId",
      },
      nullable: true,
      onDelete: "CASCADE",
    },
    uploader: {
      type: "many-to-one",
      target: "User",
      joinColumn: {
        name: "uploadedByRut",
        referencedColumnName: "rut",
      },
      nullable: false,
      onDelete: "SET NULL",
    },
  },
  indices: [
    {
      name: "IDX_EVENTO_MULTIMEDIA_EVENTO",
      columns: ["eventoDeportivoId"],
    },
    {
      name: "IDX_EVENTO_MULTIMEDIA_EVENTO_GENERAL",
      columns: ["eventoId"],
    },
    {
      name: "IDX_EVENTO_MULTIMEDIA_PRIVACIDAD",
      columns: ["isPrivate"],
    },
    {
      name: "IDX_EVENTO_MULTIMEDIA_FECHA",
      columns: ["createdAt"],
    },
  ],
});

export default EventoMultimediaSchema;
