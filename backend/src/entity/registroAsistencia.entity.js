import { EntitySchema } from "typeorm";

export const RegistroAsistenciaSchema = new EntitySchema({
  name: "RegistroAsistencia",
  tableName: "registros_asistencia",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    sesionId: {
      type: "int",
      nullable: false,
      comment: "ID de la sesión de asistencia",
    },
    rutEstudiante: {
      type: "varchar",
      length: 15,
      nullable: false,
      comment: "RUT del estudiante",
    },
    nombreEstudiante: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre completo del estudiante",
    },
    estado: {
      type: "enum",
      enum: ["presente", "ausente", "justificado"],
      nullable: false,
      default: "presente",
      comment: "Estado de asistencia",
    },
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones adicionales",
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
  relations: {
    sesion: {
      target: "SesionAsistencia",
      type: "many-to-one",
      joinColumn: {
        name: "sesionId",
        referencedColumnName: "id",
      },
    },
  },
});
