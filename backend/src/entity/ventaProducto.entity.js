"use strict";
import { EntitySchema } from "typeorm";

const VentaProductoSchema = new EntitySchema({
  name: "VentaProducto",
  tableName: "ventas_productos",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    // Referencias
    productoId: {
      type: "uuid",
      nullable: false,
      comment: "ID del producto vendido",
    },
    compradorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del comprador (apoderado/miembro)",
    },
    inscripcionId: {
      type: "uuid",
      nullable: true,
      comment: "ID de inscripción asociada (si aplica)",
    },
    // Información de la Venta
    numeroVenta: {
      type: "varchar",
      length: 50,
      nullable: false,
      unique: true,
      comment: "Número único de la venta (ej: VT2024-001)",
    },
    cantidad: {
      type: "int",
      nullable: false,
      comment: "Cantidad de productos vendidos",
    },
    variante: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Variante específica (talla XL, color azul, etc)",
    },
    // Precios
    precioUnitario: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Precio unitario al momento de la venta",
    },
    descuento: {
      type: "decimal",
      precision: 10,
      scale: 2,
      default: 0,
      comment: "Descuento aplicado (precio miembro, promoción, etc)",
    },
    subtotal: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Subtotal (cantidad × precio - descuento)",
    },
    impuestos: {
      type: "decimal",
      precision: 10,
      scale: 2,
      default: 0,
      comment: "Impuestos aplicados (si aplica)",
    },
    total: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Total de la venta",
    },
    // Información de Entrega
    fechaVenta: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
      comment: "Fecha y hora de la venta",
    },
    estado: {
      type: "enum",
      enum: ["pendiente", "pagado", "entregado", "cancelado"],
      default: "pendiente",
      nullable: false,
      comment: "Estado de la venta",
    },
    fechaEntrega: {
      type: "date",
      nullable: true,
      comment: "Fecha de entrega programada",
    },
    fechaEntregaReal: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Fecha real de entrega",
    },
    // Método de Pago
    metodoPago: {
      type: "enum",
      enum: ["efectivo", "transferencia", "tarjeta", "descuento_mensualidad", "credito"],
      nullable: false,
      comment: "Método de pago utilizado",
    },
    referenciaPago: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Referencia del pago (número operación, etc)",
    },
    fechaPago: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Fecha del pago",
    },
    // Información Adicional
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones de la venta",
    },
    instruccionesEntrega: {
      type: "text",
      nullable: true,
      comment: "Instrucciones especiales de entrega",
    },
    // Personal Responsable
    vendidoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT de quien registró la venta",
    },
    entregadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT de quien entregó el producto",
    },
    // Devoluciones
    devuelto: {
      type: "boolean",
      default: false,
      comment: "Si el producto fue devuelto",
    },
    fechaDevolucion: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Fecha de devolución",
    },
    motivoDevolucion: {
      type: "text",
      nullable: true,
      comment: "Motivo de la devolución",
    },
    // Metadatos
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
    producto: {
      type: "many-to-one",
      target: "Producto",
      joinColumn: { name: "productoId" },
      onDelete: "CASCADE",
    },
    comprador: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "compradorRut", referencedColumnName: "rut" },
    },
    inscripcion: {
      type: "many-to-one",
      target: "Inscripcion",
      joinColumn: { name: "inscripcionId" },
      nullable: true,
    },
    vendidoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "vendidoPorRut", referencedColumnName: "rut" },
    },
    entregadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "entregadoPorRut", referencedColumnName: "rut" },
      nullable: true,
    },
  },
  indices: [
    {
      name: "IDX_VENTA_NUMERO",
      columns: ["numeroVenta"],
      unique: true,
    },
    {
      name: "IDX_VENTA_PRODUCTO",
      columns: ["productoId"],
    },
    {
      name: "IDX_VENTA_COMPRADOR",
      columns: ["compradorRut"],
    },
    {
      name: "IDX_VENTA_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_VENTA_FECHA",
      columns: ["fechaVenta"],
    },
    {
      name: "IDX_VENTA_METODO_PAGO",
      columns: ["metodoPago"],
    },
    {
      name: "IDX_VENTA_INSCRIPCION",
      columns: ["inscripcionId"],
    },
  ],
});

export default VentaProductoSchema;
