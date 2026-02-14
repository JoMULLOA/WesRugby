"use strict";
import { EntitySchema } from "typeorm";

const EntrenadorPublicoSchema = new EntitySchema({
  name: "EntrenadorPublico",
  tableName: "entrenadores_publicos",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    userRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      unique: true,
    },
    titulo: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Título profesional o deportivo del entrenador",
    },
    especialidad: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Especialidad o área de expertise",
    },
    aniosExperiencia: {
      type: "int",
      nullable: true,
      comment: "Años de experiencia en rugby",
    },
    certificaciones: {
      type: "text",
      nullable: true,
      comment: "Certificaciones y cursos relevantes (JSON o texto)",
    },
    logros: {
      type: "text",
      nullable: true,
      comment: "Logros y reconocimientos destacados",
    },
    biografia: {
      type: "text",
      nullable: true,
      comment: "Biografía o descripción del entrenador",
    },
    categorias: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Categorías que entrena",
    },
    visible: {
      type: "boolean",
      default: true,
      nullable: false,
      comment: "Si el perfil es visible públicamente",
    },
    ordenVisualizacion: {
      type: "int",
      default: 0,
      nullable: false,
      comment: "Orden de visualización en la página pública",
    },
    fotoPath: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Ruta del archivo de foto pública del entrenador",
    },
    fotoVersion: {
      type: "int",
      default: 0,
      nullable: false,
      comment: "Versión de la foto pública para control de caché",
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
    user: {
      type: "many-to-one",
      target: "User",
      joinColumn: {
        name: "userRut",
        referencedColumnName: "rut",
      },
      onDelete: "CASCADE",
    },
  },
  indices: [
    {
      name: "IDX_ENTRENADOR_PUBLICO_USER_RUT",
      columns: ["userRut"],
      unique: true,
    },
  ],
});

export default EntrenadorPublicoSchema;
