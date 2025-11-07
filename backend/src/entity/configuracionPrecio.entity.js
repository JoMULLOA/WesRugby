"use strict";
import { EntitySchema } from "typeorm";

const ConfiguracionPrecioSchema = new EntitySchema({
  name: "ConfiguracionPrecio",
  tableName: "configuracion_precios",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    anio: {
      type: "int",
      nullable: false,
    },
    precioMensualidad: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
    },
    descuentoMensualidad2: {
      type: "int",
      nullable: false,
      default: 0,
    },
    descuentoMensualidad3Plus: {
      type: "int",
      nullable: false,
      default: 0,
    },
    precioMatricula: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
    },
    descuentoMatricula2: {
      type: "int",
      nullable: false,
      default: 0,
    },
    descuentoMatricula3Plus: {
      type: "int",
      nullable: false,
      default: 0,
    },
    fechaCreacion: {
      type: "timestamp with time zone",
      createDate: true,
    },
    fechaActualizacion: {
      type: "timestamp with time zone",
      updateDate: true,
    },
  },
  indices: [
    {
      name: "IDX_CONFIGURACION_PRECIO_ANIO",
      columns: ["anio"],
      unique: true,
    },
  ],
});

export default ConfiguracionPrecioSchema;
