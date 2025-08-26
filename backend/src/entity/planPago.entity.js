"use strict";
import { EntitySchema } from "typeorm";

const PlanPagoSchema = new EntitySchema({
  name: "PlanPago",
  tableName: "planes_pago",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    nombre: {
      type: "varchar",
      length: 100,
      nullable: false,
      comment: "Ej: Plan Mensual Básico, Plan Anual con Descuento",
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción detallada del plan",
    },
    tipoCategoria: {
      type: "enum",
      enum: ["infantil", "juvenil", "senior", "especial"],
      nullable: false,
      comment: "Categoría etaria del plan",
    },
    modalidad: {
      type: "enum",
      enum: ["mensual", "trimestral", "semestral", "anual"],
      nullable: false,
      comment: "Modalidad de pago",
    },
    montoBase: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Monto base del plan en pesos chilenos",
    },
    descuentoHermanos: {
      type: "decimal",
      precision: 5,
      scale: 2,
      default: 0,
      comment: "Porcentaje de descuento por hermanos (%)",
    },
    descuentoProntoPago: {
      type: "decimal",
      precision: 5,
      scale: 2,
      default: 0,
      comment: "Porcentaje de descuento por pago anticipado (%)",
    },
    incluye: {
      type: "jsonb",
      nullable: true,
      comment: "Array de servicios incluidos (entrenamientos, uniformes, etc)",
    },
    restricciones: {
      type: "jsonb",
      nullable: true,
      comment: "Restricciones del plan (edad mínima/máxima, requisitos, etc)",
    },
    // Vigencia del Plan
    fechaInicioVigencia: {
      type: "date",
      nullable: false,
      comment: "Fecha de inicio de vigencia del plan",
    },
    fechaFinVigencia: {
      type: "date",
      nullable: true,
      comment: "Fecha de fin de vigencia (null = indefinido)",
    },
    activo: {
      type: "boolean",
      default: true,
      nullable: false,
      comment: "Si el plan está disponible para nuevas inscripciones",
    },
    // Configuración de Pagos
    diasGracia: {
      type: "int",
      default: 5,
      comment: "Días de gracia después del vencimiento",
    },
    multaMora: {
      type: "decimal",
      precision: 10,
      scale: 2,
      default: 0,
      comment: "Multa por mora (monto fijo)",
    },
    interesMora: {
      type: "decimal",
      precision: 5,
      scale: 2,
      default: 0,
      comment: "Interés por mora (% mensual)",
    },
    // Metadatos
    creadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que creó el plan",
    },
    observaciones: {
      type: "text",
      nullable: true,
    },
    orden: {
      type: "int",
      default: 0,
      comment: "Orden de visualización en listas",
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
    creadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "creadoPorRut", referencedColumnName: "rut" },
    },
    inscripciones: {
      type: "one-to-many",
      target: "Inscripcion",
      inverseSide: "planPago",
    },
  },
  indices: [
    {
      name: "IDX_PLAN_PAGO_ACTIVO",
      columns: ["activo"],
    },
    {
      name: "IDX_PLAN_PAGO_CATEGORIA",
      columns: ["tipoCategoria"],
    },
    {
      name: "IDX_PLAN_PAGO_MODALIDAD",
      columns: ["modalidad"],
    },
    {
      name: "IDX_PLAN_PAGO_VIGENCIA",
      columns: ["fechaInicioVigencia", "fechaFinVigencia"],
    },
  ],
});

export default PlanPagoSchema;
