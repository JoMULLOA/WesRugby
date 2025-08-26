"use strict";
import { EntitySchema } from "typeorm";

const EventoDeportivoSchema = new EntitySchema({
  name: "EventoDeportivo",
  tableName: "eventos_deportivos",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    // Información Básica del Evento
    titulo: {
      type: "varchar",
      length: 200,
      nullable: false,
      comment: "Título del evento (ej: Entrenamiento Juvenil, Partido vs Club XYZ)",
    },
    descripcion: {
      type: "text",
      nullable: true,
      comment: "Descripción detallada del evento",
    },
    tipoEvento: {
      type: "enum",
      enum: ["entrenamiento", "partido", "torneo", "reunion", "evento_social", "viaje", "otro"],
      nullable: false,
      comment: "Tipo de evento",
    },
    categoria: {
      type: "varchar",
      length: 50,
      nullable: true,
      comment: "Categoría participante (infantil, juvenil, senior, mixto)",
    },
    // Fechas y Horarios
    fechaInicio: {
      type: "timestamp with time zone",
      nullable: false,
      comment: "Fecha y hora de inicio",
    },
    fechaFin: {
      type: "timestamp with time zone",
      nullable: true,
      comment: "Fecha y hora de fin",
    },
    duracionEstimada: {
      type: "int",
      nullable: true,
      comment: "Duración estimada en minutos",
    },
    // Ubicación
    lugar: {
      type: "varchar",
      length: 200,
      nullable: false,
      comment: "Lugar donde se realizará el evento",
    },
    direccion: {
      type: "text",
      nullable: true,
      comment: "Dirección completa del lugar",
    },
    coordenadas: {
      type: "point",
      nullable: true,
      comment: "Coordenadas GPS del lugar",
    },
    // Participantes
    equiposParticipantes: {
      type: "jsonb",
      nullable: true,
      comment: "Lista de equipos participantes (para partidos/torneos)",
    },
    capacidadMaxima: {
      type: "int",
      nullable: true,
      comment: "Capacidad máxima de participantes",
    },
    inscripcionRequerida: {
      type: "boolean",
      default: false,
      comment: "Si requiere inscripción previa",
    },
    // Recursos y Equipamiento
    recursosNecesarios: {
      type: "jsonb",
      nullable: true,
      comment: "Lista de recursos/equipamiento necesario",
    },
    equiposAsignados: {
      type: "jsonb",
      nullable: true,
      comment: "Equipamiento asignado para el evento",
    },
    responsableEquipamiento: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT del responsable del equipamiento",
    },
    // Estado y Gestión
    estado: {
      type: "enum",
      enum: ["programado", "confirmado", "en_curso", "finalizado", "cancelado", "pospuesto"],
      default: "programado",
      nullable: false,
      comment: "Estado del evento",
    },
    esRecurrente: {
      type: "boolean",
      default: false,
      comment: "Si es un evento recurrente",
    },
    patronRecurrencia: {
      type: "jsonb",
      nullable: true,
      comment: "Patrón de recurrencia (semanal, mensual, etc)",
    },
    // Información Adicional
    requiereTransporte: {
      type: "boolean",
      default: false,
      comment: "Si se requiere coordinación de transporte",
    },
    costo: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: true,
      comment: "Costo del evento (si aplica)",
    },
    observaciones: {
      type: "text",
      nullable: true,
      comment: "Observaciones adicionales",
    },
    // Clima y Condiciones
    condicionesClimaticas: {
      type: "varchar",
      length: 100,
      nullable: true,
      comment: "Condiciones climáticas esperadas",
    },
    planAlternativo: {
      type: "text",
      nullable: true,
      comment: "Plan alternativo en caso de mal clima",
    },
    // Responsables
    organizadoPorRut: {
      type: "varchar",
      length: 12,
      nullable: false,
      comment: "RUT de quien organizó el evento",
    },
    entrenadorAsignado: {
      type: "varchar",
      length: 12,
      nullable: true,
      comment: "RUT del entrenador asignado",
    },
    // Resultados (para partidos/torneos)
    resultado: {
      type: "jsonb",
      nullable: true,
      comment: "Resultado del evento (scores, posiciones, etc)",
    },
    // Notificaciones
    notificarParticipantes: {
      type: "boolean",
      default: true,
      comment: "Si notificar a los participantes",
    },
    fechaLimiteInscripcion: {
      type: "date",
      nullable: true,
      comment: "Fecha límite para inscribirse",
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
    organizadoPor: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "organizadoPorRut", referencedColumnName: "rut" },
    },
    entrenador: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "entrenadorAsignado", referencedColumnName: "rut" },
      nullable: true,
    },
    responsableEquipo: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "responsableEquipamiento", referencedColumnName: "rut" },
      nullable: true,
    },
    asistencias: {
      type: "one-to-many",
      target: "Asistencia",
      inverseSide: "evento",
    },
  },
  indices: [
    {
      name: "IDX_EVENTO_FECHA_INICIO",
      columns: ["fechaInicio"],
    },
    {
      name: "IDX_EVENTO_TIPO",
      columns: ["tipoEvento"],
    },
    {
      name: "IDX_EVENTO_CATEGORIA",
      columns: ["categoria"],
    },
    {
      name: "IDX_EVENTO_ESTADO",
      columns: ["estado"],
    },
    {
      name: "IDX_EVENTO_ORGANIZADOR",
      columns: ["organizadoPorRut"],
    },
    {
      name: "IDX_EVENTO_ENTRENADOR",
      columns: ["entrenadorAsignado"],
    },
    {
      name: "IDX_EVENTO_RECURRENTE",
      columns: ["esRecurrente"],
    },
  ],
});

export default EventoDeportivoSchema;
