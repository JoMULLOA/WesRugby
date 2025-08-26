"use strict";
import { EntitySchema } from "typeorm";

const DirectivaSchema = new EntitySchema({
  name: "Directiva",
  tableName: "directiva",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    // Información del Cargo
    cargo: {
      type: "enum",
      enum: [
        "presidente", 
        "vicepresidente", 
        "secretario", 
        "tesorero", 
        "director_deportivo",
        "director_tecnico",
        "vocal",
        "delegado",
        "coordinador_juvenil",
        "coordinador_infantil",
        "otro"
      ],
      nullable: false,
      comment: "Cargo en la directiva",
    },
    cargoDescripcion: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Descripción específica del cargo (si cargo = 'otro')",
    },
    // Persona Asignada
    personaRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT de la persona asignada al cargo",
    },
    // Períodos de Gestión
    fechaInicio: {
      type: "date",
      nullable: false,
      comment: "Fecha de inicio del período",
    },
    fechaFin: {
      type: "date",
      nullable: true,
      comment: "Fecha de fin del período (null = indefinido/actual)",
    },
    activo: {
      type: "boolean",
      default: true,
      nullable: false,
      comment: "Si el cargo está actualmente activo",
    },
    // Responsabilidades
    responsabilidades: {
      type: "jsonb",
      nullable: true,
      comment: "Lista de responsabilidades específicas del cargo",
    },
    permisos: {
      type: "jsonb",
      nullable: true,
      comment: "Permisos específicos en el sistema",
    },
    // Información de Contacto Específica del Cargo
    emailCargo: {
      type: "varchar",
      length: 255,
      nullable: true,
      comment: "Email específico del cargo (ej: presidente@wessexrugby.cl)",
    },
    telefonoCargo: {
      type: "varchar",
      length: 15,
      nullable: true,
      comment: "Teléfono específico del cargo",
    },
    // Estado del Cargo
    motivoCambio: {
      type: "enum",
      enum: [
        "eleccion_periodo",
        "renuncia", 
        "relevo_temporal",
        "reorganizacion",
        "creacion_cargo",
        "eliminacion_cargo",
        "otro"
      ],
      nullable: true,
      comment: "Motivo del cambio (para histórico)",
    },
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones del cambio o período",
    },
    // Datos del Cambio
    cambiadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT de quien realizó el cambio",
    },
    fechaCambio: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Fecha del cambio",
    },
    // Orden y Jerarquía
    orden: {
      type: "int",
      default: 0,
      comment: "Orden jerárquico del cargo (para visualización)",
    },
    nivelAcceso: {
      type: "enum",
      enum: ["alto", "medio", "basico"],
      default: "basico",
      comment: "Nivel de acceso en el sistema",
    },
    // Información de Elección/Nombramiento
    formaDesignacion: {
      type: "enum",
      enum: ["eleccion", "nombramiento", "sucesion", "temporal"],
      nullable: true,
      comment: "Forma de designación al cargo",
    },
    fechaEleccion: {
      type: "date",
      nullable: true,
      comment: "Fecha de elección (si aplica)",
    },
    votosRecibidos: {
      type: "int",
      nullable: true,
      comment: "Votos recibidos en elección (si aplica)",
    },
    // Documentación
    actaNombramiento: {
      type: "varchar",
      length: 500,
      nullable: true,
      comment: "Ruta del acta de nombramiento",
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
    persona: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "personaRut", referencedColumnName: "rut" },
      onDelete: "CASCADE",
    },
    cambiadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "cambiadoPorRut", referencedColumnName: "rut" },
      nullable: true,
    },
  },
  indices: [
    {
      name: "IDX_DIRECTIVA_CARGO",
      columns: ["cargo"],
    },
    {
      name: "IDX_DIRECTIVA_PERSONA",
      columns: ["personaRut"],
    },
    {
      name: "IDX_DIRECTIVA_ACTIVO",
      columns: ["activo"],
    },
    {
      name: "IDX_DIRECTIVA_FECHA_INICIO",
      columns: ["fechaInicio"],
    },
    {
      name: "IDX_DIRECTIVA_ORDEN",
      columns: ["orden"],
    },
    {
      name: "IDX_DIRECTIVA_NIVEL_ACCESO",
      columns: ["nivelAcceso"],
    },
    {
      name: "IDX_DIRECTIVA_CARGO_ACTIVO",
      columns: ["cargo", "activo"],
    },
  ],
});

export default DirectivaSchema;
