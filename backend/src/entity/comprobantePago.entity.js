"use strict";
import { EntitySchema } from "typeorm";

const ComprobantePagoSchema = new EntitySchema({
  name: "ComprobantePago",
  tableName: "comprobantes_pago",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    // Referencias
    inscripcionId: {
      type: "uuid",
      nullable: false,
      comment: "ID de la inscripción asociada",
    },
    // Información del Pago
    numeroComprobante: {
      type: "varchar",
      length: 50,
      nullable: false,
      unique: true,
      comment: "Número único del comprobante (ej: WR2024-001)",
    },
    tipoPago: {
      type: "enum",
      enum: ["mensualidad", "matricula", "uniforme", "evento_especial", "multa", "otro"],
      nullable: false,
      comment: "Tipo de pago",
    },
    metodoPago: {
      type: "enum",
      enum: ["transferencia", "deposito", "efectivo", "cheque", "tarjeta"],
      nullable: false,
      comment: "Método de pago utilizado",
    },
    // Montos
    montoTotal: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Monto total pagado",
    },
    montoBase: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Monto base sin descuentos ni recargos",
    },
    descuentos: {
      type: "decimal",
      precision: 10,
      scale: 2,
      default: 0,
      comment: "Descuentos aplicados",
    },
    recargos: {
      type: "decimal",
      precision: 10,
      scale: 2,
      default: 0,
      comment: "Recargos por mora u otros conceptos",
    },
    // Fechas
    fechaPago: {
      type: "date",
      nullable: false,
      comment: "Fecha en que se realizó el pago",
    },
    fechaVencimiento: {
      type: "date",
      nullable: true,
      comment: "Fecha de vencimiento del pago",
    },
    mesCorrespondiente: {
      type: "varchar",
      length: 7,
      nullable: false,
      comment: "Mes al que corresponde el pago (formato: YYYY-MM)",
    },
    // Información Bancaria
    bancoOrigen: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Banco desde donde se realizó la transferencia",
    },
    numeroOperacion: {
      type: "varchar",
      length: 50,
      nullable: true,
      comment: "Número de operación bancaria",
    },
    cuentaDestino: {
      type: "varchar",
      length: 50,
      nullable: true,
      comment: "Cuenta de destino del club",
    },
    // Archivos Adjuntos
    rutaComprobante: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Ruta del archivo del comprobante subido",
    },
    nombreArchivoOriginal: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Nombre original del archivo subido",
    },
    tipoArchivo: {
      type: "varchar",
      length: 10,
      nullable: true,
      comment: "Extensión del archivo (jpg, png, pdf, etc)",
    },
    tamañoArchivo: {
      type: "int",
      nullable: true,
      comment: "Tamaño del archivo en bytes",
    },
    // Estado y Validación
    estado: {
      type: "enum",
      enum: ["pendiente", "validado", "rechazado", "observado"],
      default: "pendiente",
      nullable: false,
      comment: "Estado del comprobante",
    },
    fechaSubida: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
      comment: "Cuándo se subió el comprobante",
    },
    fechaValidacion: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Cuándo se validó/rechazó el comprobante",
    },
    validadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT de quien validó el comprobante (tesorera/directiva)",
    },
    // Observaciones
    observacionesApoderado: {
      type: "text",
      nullable: true,
      comment: "Observaciones del apoderado al subir el comprobante",
    },
    observacionesTesorera: {
      type: "text",
      nullable: true,
      comment: "Observaciones de la tesorera al validar",
    },
    motivoRechazo: {
      type: "text",
      nullable: true,
      comment: "Motivo del rechazo si aplica",
    },
    // Quien Subió el Comprobante
    subidoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT de quien subió el comprobante (apoderado/directiva)",
    },
    // Notificaciones
    notificacionEnviada: {
      type: "boolean",
      default: false,
      comment: "Si se envió notificación de validación",
    },
    fechaNotificacion: {
      type: "timestamp with time zone",
      nullable: true,
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
    inscripcion: {
      type: "many-to-one",
      target: "Inscripcion",
      joinColumn: { name: "inscripcionId" },
      onDelete: "CASCADE",
    },
    subidoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "subidoPorRut", referencedColumnName: "rut" },
    },
    validadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "validadoPorRut", referencedColumnName: "rut" },
      nullable: true,
    },
  },
  indices: [
    {
      name: "IDX_COMPROBANTE_NUMERO",
      columns: ["numeroComprobante"],
      unique: true,
    },
    {
      name: "IDX_COMPROBANTE_INSCRIPCION",
      columns: ["inscripcionId"],
    },
    {
      name: "IDX_COMPROBANTE_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_COMPROBANTE_FECHA_PAGO",
      columns: ["fechaPago"],
    },
    {
      name: "IDX_COMPROBANTE_MES",
      columns: ["mesCorrespondiente"],
    },
    {
      name: "IDX_COMPROBANTE_TIPO",
      columns: ["tipoPago"],
    },
    {
      name: "IDX_COMPROBANTE_SUBIDO_POR",
      columns: ["subidoPorRut"],
    },
    {
      name: "IDX_COMPROBANTE_VALIDADO_POR",
      columns: ["validadoPorRut"],
    },
  ],
});

export default ComprobantePagoSchema;
