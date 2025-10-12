import { EntitySchema } from "typeorm";

const TipoEvento = new EntitySchema({
  name: "TipoEvento",
  tableName: "tipos_evento",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid"
    },
    nombre: {
      type: "varchar",
      length: 100,
      nullable: false,
      unique: true
    },
    esDeportivo: {
      type: "boolean",
      nullable: false,
      default: false
    },
    activo: {
      type: "boolean",
      nullable: false,
      default: true
    },
    fechaCreacion: {
      type: "timestamp",
      createDate: true
    },
    fechaActualizacion: {
      type: "timestamp",
      updateDate: true
    }
  },
  relations: {
    eventos: {
      type: "one-to-many",
      target: "EventoDeportivo",
      inverseSide: "tipoEvento"
    }
  }
});

export default TipoEvento;