"use strict";
import { EntitySchema } from "typeorm";

const NoticiaSchema = new EntitySchema({
  name: "Noticia",
  tableName: "noticias",
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
      comment: "Título de la noticia",
    },
    descripcion: {
      type: "text",
      nullable: false,
      comment: "Descripción detallada de la noticia",
    },
    imagen: {
      type: "varchar",
      length: 500,
      nullable: false,
      comment: "URL de la imagen de la noticia",
    },
    fechaPublicacion: {
      type: "date",
      nullable: false,
      comment: "Fecha de publicación de la noticia",
    },
    estado: {
      type: "enum",
      enum: ["borrador", "publicada", "archivada"],
      default: "borrador",
      nullable: false,
      comment: "Estado de la noticia",
    },
    destacada: {
      type: "boolean",
      default: false,
      nullable: false,
      comment: "Si la noticia está destacada en el home",
    },
    rutCreador: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó la noticia (directiva)",
    },
    nombreCreador: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre completo del creador",
    },
    orden: {
      type: "int",
      default: 0,
      nullable: false,
      comment: "Orden de visualización en el home",
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
      name: "IDX_NOTICIA_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_NOTICIA_FECHA",
      columns: ["fechaPublicacion"],
    },
    {
      name: "IDX_NOTICIA_DESTACADA",
      columns: ["destacada"],
    },
    {
      name: "IDX_NOTICIA_ORDEN",
      columns: ["orden"],
    },
  ],
});

export default NoticiaSchema;
