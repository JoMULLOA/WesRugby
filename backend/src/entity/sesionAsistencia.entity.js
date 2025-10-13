import { EntitySchema } from "typeorm";

export const SesionAsistenciaSchema = new EntitySchema({
  name: "SesionAsistencia",
  tableName: "sesiones_asistencia",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    nombre: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre de la sesión"
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción de la sesión"
    },
    fecha: {
      type: "date",
      nullable: false,
      comment: "Fecha de la sesión"
    },
    curso: {
      type: "varchar",
      length: 100,
      nullable: false,
      comment: "Curso al que pertenece la sesión"
    },
    rutEntrenador: {
      type: "varchar",
      length: 15,
      nullable: false,
      comment: "RUT del entrenador"
    },
    nombreEntrenador: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre del entrenador"
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
});