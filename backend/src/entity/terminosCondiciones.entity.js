import { EntitySchema } from "typeorm";

export const TerminosCondicionesSchema = new EntitySchema({
  name: "TerminosCondiciones",
  tableName: "terminos_condiciones",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    version: {
      type: "varchar",
      length: 20,
      nullable: false,
      comment: "Versión del término (ej: 1.0, 2.0)",
    },
    titulo: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Título del documento",
    },
    contenido: {
      type: "text",
      nullable: false,
      comment: "Contenido completo de los términos y condiciones",
    },
    activo: {
      type: "boolean",
      default: true,
      comment: "Indica si esta versión está activa",
    },
    creadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario de directiva que creó/editó los términos",
    },
    fechaCreacion: {
      type: "timestamp",
      default: () => "CURRENT_TIMESTAMP",
      comment: "Fecha de creación del registro",
    },
    fechaActivacion: {
      type: "timestamp",
      nullable: true,
      comment: "Fecha en que se activó esta versión",
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
      name: "IDX_terminos_activo",
      columns: ["activo"],
    },
  ],
});
