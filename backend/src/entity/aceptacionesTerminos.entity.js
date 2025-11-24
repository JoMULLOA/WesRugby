import { EntitySchema } from "typeorm";

export const AceptacionesTerminosSchema = new EntitySchema({
  name: "AceptacionesTerminos",
  tableName: "aceptaciones_terminos",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    apoderadoRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del apoderado que aceptó los términos",
    },
    terminoId: {
      type: "int",
      nullable: false,
      comment: "ID del término aceptado",
    },
    version: {
      type: "varchar",
      length: 20,
      nullable: false,
      comment: "Versión del término aceptado",
    },
    fechaAceptacion: {
      type: "timestamp",
      default: () => "CURRENT_TIMESTAMP",
      comment: "Fecha y hora de aceptación",
    },
    ipAddress: {
      type: "varchar",
      length: 45,
      nullable: true,
      comment: "Dirección IP desde donde se aceptó",
    },
    userAgent: {
      type: "text",
      nullable: true,
      comment: "User agent del navegador",
    },
    createdAt: {
      type: "timestamp",
      createDate: true,
    },
    updatedAt: {
      type: "timestamp",
      updateDate: true,
    },
  },
  indices: [
    {
      name: "IDX_aceptaciones_apoderado",
      columns: ["apoderadoRut"],
    },
    {
      name: "IDX_aceptaciones_termino",
      columns: ["terminoId"],
    },
    {
      name: "UQ_apoderado_termino",
      unique: true,
      columns: ["apoderadoRut", "terminoId"],
    },
  ],
  relations: {
    termino: {
      type: "many-to-one",
      target: "TerminosCondiciones",
      joinColumn: {
        name: "terminoId",
      },
      onDelete: "CASCADE",
    },
  },
});
