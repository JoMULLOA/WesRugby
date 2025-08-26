"use strict";
import { EntitySchema } from "typeorm";

const ProductoSchema = new EntitySchema({
  name: "Producto",
  tableName: "productos",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    // Información Básica
    codigo: {
      type: "varchar",
      length: 50,
      nullable: false,
      unique: true,
      comment: "Código único del producto (ej: WR-POL-001)",
    },
    nombre: {
      type: "varchar",
      length: 200,
      nullable: false,
      comment: "Nombre del producto",
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción detallada del producto",
    },
    categoria: {
      type: "enum",
      enum: ["uniforme", "poleron", "camiseta", "shorts", "medias", "accesorios", "llaveros", "merchandising", "equipamiento", "otro"],
      nullable: false,
      comment: "Categoría del producto",
    },
    // Precios
    precioVenta: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Precio de venta al público",
    },
    precioMiembro: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: true,
      comment: "Precio especial para miembros del club",
    },
    precioCosto: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: true,
      comment: "Precio de costo/compra",
    },
    // Inventario
    stockActual: {
      type: "int",
      default: 0,
      nullable: false,
      comment: "Stock actual disponible",
    },
    stockMinimo: {
      type: "int",
      default: 5,
      nullable: false,
      comment: "Stock mínimo antes de reordenar",
    },
    stockMaximo: {
      type: "int",
      nullable: true,
      comment: "Stock máximo recomendado",
    },
    // Variantes (tallas, colores, etc)
    tieneVariantes: {
      type: "boolean",
      default: false,
      comment: "Si el producto tiene variantes (tallas, colores)",
    },
    variantes: {
      type: "jsonb",
      nullable: true,
      comment: "Variantes disponibles con su stock individual",
    },
    // Información Física
    peso: {
      type: "decimal",
      precision: 8,
      scale: 3,
      nullable: true,
      comment: "Peso en kilogramos",
    },
    dimensiones: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Dimensiones (largo x ancho x alto)",
    },
    // Proveedor
    proveedor: {
      type: "varchar",
      length: 200,
      nullable: true,
      comment: "Nombre del proveedor",
    },
    codigoProveedor: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Código del producto en el proveedor",
    },
    tiempoEntrega: {
      type: "int",
      nullable: true,
      comment: "Tiempo de entrega del proveedor (en días)",
    },
    // Estado
    activo: {
      type: "boolean",
      default: true,
      nullable: false,
      comment: "Si el producto está activo para venta",
    },
    disponibleOnline: {
      type: "boolean",
      default: true,
      comment: "Si está disponible para compra online",
    },
    requiereAprobacion: {
      type: "boolean",
      default: false,
      comment: "Si las compras requieren aprobación",
    },
    // Imágenes y Multimedia
    imagenPrincipal: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Ruta de la imagen principal",
    },
    imagenesAdicionales: {
      type: "jsonb",
      nullable: true,
      comment: "Array con rutas de imágenes adicionales",
    },
    // Información Adicional
    instruccionesUso: {
      type: "text",
      nullable: true,
      comment: "Instrucciones de uso o cuidado",
    },
    garantia: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Información de garantía",
    },
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones internas",
    },
    // Estadísticas
    ventasTotal: {
      type: "int",
      default: 0,
      comment: "Total de unidades vendidas",
    },
    fechaUltimaVenta: {
      type: "date",
      nullable: true,
      comment: "Fecha de la última venta",
    },
    // Gestión
    creadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT de quien creó el producto",
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
    creadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "creadoPorRut", referencedColumnName: "rut" },
    },
    ventas: {
      type: "one-to-many",
      target: "VentaProducto",
      inverseSide: "producto",
    },
  },
  indices: [
    {
      name: "IDX_PRODUCTO_CODIGO",
      columns: ["codigo"],
      unique: true,
    },
    {
      name: "IDX_PRODUCTO_CATEGORIA",
      columns: ["categoria"],
    },
    {
      name: "IDX_PRODUCTO_ACTIVO",
      columns: ["activo"],
    },
    {
      name: "IDX_PRODUCTO_STOCK",
      columns: ["stockActual"],
    },
    {
      name: "IDX_PRODUCTO_DISPONIBLE_ONLINE",
      columns: ["disponibleOnline"],
    },
  ],
});

export default ProductoSchema;
