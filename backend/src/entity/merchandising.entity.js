"use strict";
import { EntitySchema } from "typeorm";

const MerchandisingSchema = new EntitySchema({
  name: "Merchandising",
  tableName: "merchandising",
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
      comment: "Nombre del producto"
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción del producto"
    },
    imagen: {
      type: "varchar",
      length: 500,
      nullable: false,
      comment: "URL de la imagen del producto"
    },
    precio: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Precio del producto"
    },
    moneda: {
      type: "varchar",
      length: 5,
      default: "CLP",
      nullable: false,
      comment: "Moneda del precio"
    },
    disponible: {
      type: "boolean",
      default: true,
      nullable: false,
      comment: "Si el producto está disponible"
    },
    stock: {
      type: "int",
      nullable: true,
      comment: "Cantidad en stock (opcional)"
    },
    categoria: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Categoría del producto (camisetas, accesorios, etc.)"
    },
    estado: {
      type: "enum",
      enum: ["activo", "inactivo"],
      default: "activo",
      nullable: false,
      comment: "Estado del producto"
    },
    rutCreador: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó el producto (directiva)"
    },
    nombreCreador: {
      type: "varchar",
      length: 255,
      nullable: false,
      comment: "Nombre completo del creador"
    },
    orden: {
      type: "int",
      default: 0,
      nullable: false,
      comment: "Orden de visualización en el home"
    },
    contactoVenta: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Información de contacto para la venta"
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
      name: "IDX_MERCHANDISING_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_MERCHANDISING_DISPONIBLE",
      columns: ["disponible"],
    },
    {
      name: "IDX_MERCHANDISING_CATEGORIA",
      columns: ["categoria"],
    },
    {
      name: "IDX_MERCHANDISING_ORDEN",
      columns: ["orden"],
    },
  ],
});

export default MerchandisingSchema;