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
    apoderadoRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del apoderado responsable del pago",
    },
    apoderadoEmail: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Correo del apoderado que subió el comprobante",
    },
    estudianteRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del estudiante asociado al pago",
    },
    numeroComprobante: {
      type: "varchar",
      length: 50,
      nullable: false,
      unique: true,
      comment: "Identificador legible del comprobante",
    },
    tipoPago: {
      type: "enum",
      enum: [
        "mensualidad",
        "matricula",
        "uniforme",
        "evento_especial",
        "multa",
        "otro",
      ],
      nullable: false,
      default: "mensualidad",
      comment: "Tipo de obligación cancelada",
    },
    metodoPago: {
      type: "enum",
      enum: ["transferencia", "deposito", "efectivo", "cheque", "tarjeta"],
      nullable: false,
      comment: "Método utilizado para el pago",
    },
    montoTotal: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
      comment: "Monto pagado informado",
    },
    fechaPago: {
      type: "date",
      nullable: false,
      comment: "Fecha en que se realizó el pago",
    },
    fechaVencimiento: {
      type: "date",
      nullable: true,
      comment: "Fecha de vencimiento asociada al pago",
    },
    mesCorrespondiente: {
      type: "varchar",
      length: 50,
      nullable: false,
      comment:
        "Mes facturado en formato YYYY-MM o label (ej: 'Agosto 2025', 'Multiple')",
    },
    bancoOrigen: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Banco de origen de la transferencia",
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
    rutaComprobante: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Ruta relativa del archivo cargado",
    },
    nombreArchivoOriginal: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Nombre original del archivo adjunto",
    },
    tipoArchivo: {
      type: "varchar",
      length: 50,
      nullable: true,
      comment: "Tipo MIME del archivo",
    },
    anioMatricula: {
      type: "int",
      nullable: true,
      comment: "Año de la matrícula (solo cuando tipoPago = matricula)",
    },
    tamanoArchivo: {
      type: "int",
      nullable: true,
      comment: "Tamaño del archivo en bytes",
    },
    estado: {
      type: "enum",
      enum: ["pendiente", "validado", "rechazado", "observado"],
      default: "pendiente",
      nullable: false,
      comment: "Estado de revisión del comprobante",
    },
    observacionesApoderado: {
      type: "text",
      nullable: true,
      comment: "Notas ingresadas por el apoderado",
    },
    observacionesTesorera: {
      type: "text",
      nullable: true,
      comment: "Notas ingresadas por tesorería",
    },
    motivoRechazo: {
      type: "text",
      nullable: true,
      comment: "Motivo del rechazo cuando aplica",
    },
    fechaSubida: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
      comment: "Momento en que se subió el comprobante",
    },
    fechaValidacion: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Momento en que se validó o rechazó",
    },
    validadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT del usuario que validó o rechazó",
    },
    subidoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT del usuario que registró el comprobante",
    },
    estudiantesRuts: {
      type: "jsonb",
      nullable: true,
      comment:
        "Array de RUTs de estudiantes incluidos en el pago (para pagos agrupados)",
    },
    mesesCorrespondientes: {
      type: "jsonb",
      nullable: true,
      comment: "Array de meses incluidos en el pago (formato YYYY-MM o label)",
    },
    detallesPago: {
      type: "jsonb",
      nullable: true,
      comment:
        "Detalles del pago: { estudianteRut: { meses: [...], monto: ... }, ... }",
    },
    notificacionEnviada: {
      type: "boolean",
      default: false,
      comment: "Si se envió notificación posterior",
    },
    fechaNotificacion: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Fecha de la notificación",
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
    apoderado: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "apoderadoRut", referencedColumnName: "rut" },
      onDelete: "SET NULL",
      nullable: true,
    },
    estudiante: {
      type: "many-to-one",
      target: "Estudiante",
      joinColumn: { name: "estudianteRut", referencedColumnName: "rut" },
      onDelete: "SET NULL",
      nullable: true,
    },
    subidoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "subidoPorRut", referencedColumnName: "rut" },
      onDelete: "SET NULL",
      nullable: true,
    },
    validadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "validadoPorRut", referencedColumnName: "rut" },
      onDelete: "SET NULL",
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
      name: "IDX_COMPROBANTE_APODERADO",
      columns: ["apoderadoRut"],
    },
    {
      name: "IDX_COMPROBANTE_APODERADO_EMAIL",
      columns: ["apoderadoEmail"],
    },
    {
      name: "IDX_COMPROBANTE_ESTUDIANTE",
      columns: ["estudianteRut"],
    },
    {
      name: "IDX_COMPROBANTE_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_COMPROBANTE_MES",
      columns: ["mesCorrespondiente"],
    },
    {
      name: "IDX_COMPROBANTE_FECHA",
      columns: ["fechaPago"],
    },
    {
      name: "IDX_COMPROBANTE_ANIO_MATRICULA",
      columns: ["anioMatricula"],
    },
  ],
});

export default ComprobantePagoSchema;
