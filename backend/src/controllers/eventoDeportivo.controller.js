"use strict";
import EventoDeportivo from "../entity/eventoDeportivo.entity.js";
import TipoEvento from "../entity/tipoEvento.entity.js";
import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import { In } from "typeorm";
import moment from "moment-timezone";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const eventoRepository = AppDataSource.getRepository(EventoDeportivo);
const tipoEventoRepository = AppDataSource.getRepository(TipoEvento);
const userRepository = AppDataSource.getRepository(User);
const CHILE_TZ = "America/Santiago";

function hasTimezoneInfo(value) {
  if (typeof value !== "string") {
    return false;
  }
  return /([zZ]|[+\-]\d\d:?\d\d)$/.test(value.trim());
}

function buildMoment(value) {
  if (value === null || value === undefined) {
    return null;
  }
  if (value instanceof Date || typeof value === "number") {
    const candidate = moment(value);
    return candidate.isValid() ? candidate : null;
  }
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (!trimmed) {
      return null;
    }
    const candidate = hasTimezoneInfo(trimmed)
      ? moment(trimmed)
      : moment.tz(trimmed, moment.ISO_8601, CHILE_TZ);
    return candidate.isValid() ? candidate : null;
  }
  return null;
}

function toUtcDate(value) {
  const dateMoment = buildMoment(value);
  return dateMoment ? dateMoment.toDate() : null;
}

function toChileDateOnly(value) {
  const dateMoment = buildMoment(value);
  return dateMoment ? dateMoment.tz(CHILE_TZ).startOf("day").toDate() : null;
}

function getEventStartDate(evento) {
  if (!evento) {
    return null;
  }
  const start = toUtcDate(evento.fechaInicio);
  return start || null;
}

// Crear evento deportivo (Entrenador, Directiva)
export async function crearEventoDeportivo(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["entrenador", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo entrenadores y directiva pueden crear eventos deportivos");
    }

    const {
      titulo,
      descripcion,
      tipoEventoId,
      categoria,
      fechaInicio,
      fechaFin,
      horaInicio,
      horaFin,
      lugar,
      equipoLocal,
      equipoVisitante,
      requiereInscripcion,
      cupoMaximo,
      fechaLimiteInscripcion,
      costo,
      observaciones,
      estado = "programado"
    } = req.body;

    const fechaInicioUtc = toUtcDate(fechaInicio);
    const fechaFinUtc = fechaFin ? toUtcDate(fechaFin) : null;
    const fechaLimiteUtc = fechaLimiteInscripcion
      ? toChileDateOnly(fechaLimiteInscripcion)
      : null;

    if (!fechaInicioUtc) {
      return handleErrorClient(res, 400, "Fecha inv\u00e1lida", "La fecha de inicio del evento es obligatoria.");
    }

    // Validar que el tipo de evento existe
    if (tipoEventoId) {
      const tipoEvento = await tipoEventoRepository.findOne({
        where: { id: tipoEventoId, activo: true }
      });

      if (!tipoEvento) {
        return handleErrorClient(res, 400, "Tipo de evento inválido", 
          "El tipo de evento especificado no existe o no está activo");
      }
    }

    // Validaciones básicas
    if (fechaFinUtc && fechaInicioUtc > fechaFinUtc) {
      return handleErrorClient(res, 400, "Fecha inválida", 
        "La fecha de inicio no puede ser posterior a la fecha de fin");
    }

    if (requiereInscripcion && fechaLimiteUtc) {
      if (fechaLimiteUtc > fechaInicioUtc) {
        return handleErrorClient(res, 400, "Fecha límite inválida", 
          "La fecha límite de inscripción debe ser anterior al evento");
      }
    }

    // Validación para prevenir eventos duplicados
    const eventoExistente = await eventoRepository.findOne({
      where: {
        titulo,
        fechaInicio: fechaInicioUtc,
        lugar,
        tipoEventoId,
        estado: In(["programado", "confirmado", "en_curso"])
      }
    });

    if (eventoExistente) {
      return handleErrorClient(res, 400, "Evento duplicado", 
        "Ya existe un evento con el mismo título, fecha, lugar y tipo. Por favor, modifica alguno de estos campos.");
    }

    const nuevoEvento = eventoRepository.create({
      titulo,
      descripcion,
      tipoEventoId,
      categoria,
      fechaInicio: fechaInicioUtc,
      fechaFin: fechaFinUtc,
      horaInicio,
      horaFin,
      lugar,
      equipoLocal,
      equipoVisitante,
      requiereInscripcion,
      cupoMaximo,
      fechaLimiteInscripcion: fechaLimiteUtc,
      costo: costo || 0,
      observaciones,
      estado,
      organizadoPorRut: req.user.rut
    });

    const eventoGuardado = await eventoRepository.save(nuevoEvento);

    const eventoCompleto = await eventoRepository.findOne({
      where: { id: eventoGuardado.id },
      relations: ["organizadoPor", "tipoEvento"]
    });

    handleSuccess(res, 201, "Evento deportivo creado exitosamente", eventoCompleto);

  } catch (error) {
    console.error("Error creando evento:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener eventos deportivos
export async function obtenerEventosDeportivos(req, res) {
  try {
    const {
      tipoEventoId,
      categoria,
      estado,
      fechaInicio,
      fechaFin,
      soloProximos = false,
      limite = 50,
      pagina = 1
    } = req.query;

    let whereCondition = {};

    // Aplicar filtros
    if (tipoEventoId) {
      whereCondition.tipoEventoId = tipoEventoId;
    }

    if (categoria) {
      whereCondition.categoria = categoria;
    }

    if (estado) {
      whereCondition.estado = estado;
    }

    if (fechaInicio && fechaFin) {
      whereCondition.fechaInicio = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    // Solo eventos futuros
    if (soloProximos === 'true') {
      whereCondition.fechaInicio = {
        $gte: new Date().toISOString().split('T')[0]
      };
    }

    const skip = (parseInt(pagina) - 1) * parseInt(limite);

    const [eventos, total] = await eventoRepository.findAndCount({
      where: whereCondition,
      relations: ["organizadoPor", "tipoEvento"],
      order: { fechaInicio: "DESC" },
      take: parseInt(limite),
      skip: skip
    });

    // Simplificar la respuesta para evitar problemas de serialización
    const eventosSimplificados = eventos.map(evento => ({
      id: evento.id,
      titulo: evento.titulo,
      descripcion: evento.descripcion,
      tipoEvento: evento.tipoEvento,
      categoria: evento.categoria,
      fechaInicio: evento.fechaInicio,
      fechaFin: evento.fechaFin,
      lugar: evento.lugar,
      estado: evento.estado,
      inscripcionRequerida: evento.inscripcionRequerida,
      notificarParticipantes: evento.notificarParticipantes,
      costo: evento.costo,
      observaciones: evento.observaciones,
      createdAt: evento.createdAt,
      updatedAt: evento.updatedAt
    }));

    handleSuccess(res, 200, "Eventos deportivos obtenidos exitosamente", eventosSimplificados);

  } catch (error) {
    console.error("Error obteniendo eventos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener evento por ID
export async function obtenerEventoPorId(req, res) {
  try {
    const { id } = req.params;

    const evento = await eventoRepository.findOne({
      where: { id },
      relations: ["creadoPor"]
    });

    if (!evento) {
      return handleErrorClient(res, 404, "Evento deportivo no encontrado");
    }

    handleSuccess(res, 200, "Evento deportivo obtenido exitosamente", evento);

  } catch (error) {
    console.error("Error obteniendo evento:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar evento deportivo (Entrenador, Directiva)
export async function actualizarEventoDeportivo(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (!["entrenador", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo entrenadores y directiva pueden actualizar eventos");
    }

    const evento = await eventoRepository.findOneBy({ id });
    if (!evento) {
      return handleErrorClient(res, 404, "Evento deportivo no encontrado");
    }

    // Verificar si el evento ya finalizó (solo si tiene fecha de fin)
    if (evento.fechaFin && evento.estado === "finalizado") {
      const ahora = new Date();
      const fechaFinEvento = new Date(`${evento.fechaFin}T${evento.horaFin || '23:59'}`);
      
      if (fechaFinEvento < ahora) {
        return handleErrorClient(res, 400, "Evento finalizado", 
          "No se puede modificar un evento que ya finalizó");
      }
    }

    const datosActualizacion = req.body;

    // Normalizar fechas si se actualizan
    const nuevaFechaInicio = datosActualizacion.fechaInicio
      ? toUtcDate(datosActualizacion.fechaInicio)
      : null;
    if (datosActualizacion.fechaInicio && !nuevaFechaInicio) {
      return handleErrorClient(res, 400, "Fecha inválida", "La nueva fecha de inicio no es válida.");
    }

    const nuevaFechaFin = datosActualizacion.fechaFin
      ? toUtcDate(datosActualizacion.fechaFin)
      : null;
    if (datosActualizacion.fechaFin && !nuevaFechaFin) {
      return handleErrorClient(res, 400, "Fecha inválida", "La nueva fecha de término no es válida.");
    }

    if (nuevaFechaInicio) {
      datosActualizacion.fechaInicio = nuevaFechaInicio;
    }
    if (nuevaFechaFin) {
      datosActualizacion.fechaFin = nuevaFechaFin;
    }

    if (datosActualizacion.fechaLimiteInscripcion) {
      const limite = toChileDateOnly(datosActualizacion.fechaLimiteInscripcion);
      if (!limite) {
        return handleErrorClient(res, 400, "Fecha inválida", "La nueva fecha límite no es válida.");
      }
      datosActualizacion.fechaLimiteInscripcion = limite;
    }

    const fechaInicioComparar = datosActualizacion.fechaInicio || evento.fechaInicio;
    const fechaFinComparar = datosActualizacion.fechaFin || evento.fechaFin;
    if (fechaInicioComparar && fechaFinComparar && fechaInicioComparar > fechaFinComparar) {
      return handleErrorClient(res, 400, "Fecha inválida", 
        "La fecha de inicio no puede ser posterior a la fecha de fin");
    }

    // Campos permitidos para actualización
    const camposPermitidos = [
      'titulo', 'descripcion', 'tipoEventoId', 'categoria', 'fechaInicio', 'fechaFin',
      'horaInicio', 'horaFin', 'lugar', 'equipoLocal', 'equipoVisitante',
      'requiereInscripcion', 'cupoMaximo', 'fechaLimiteInscripcion', 'costo',
      'observaciones', 'estado', 'resultadoLocal', 'resultadoVisitante'
    ];

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        evento[campo] = datosActualizacion[campo];
      }
    });

    evento.updatedAt = new Date();
    
    const eventoActualizado = await eventoRepository.save(evento);

    const eventoCompleto = await eventoRepository.findOne({
      where: { id: eventoActualizado.id },
      relations: ["organizadoPor", "tipoEvento"]
    });

    handleSuccess(res, 200, "Evento deportivo actualizado exitosamente", eventoCompleto);

  } catch (error) {
    console.error("Error actualizando evento:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Inscribirse a un evento (Todos los roles autenticados)
export async function inscribirseEvento(req, res) {
  try {
    const { id } = req.params;
    const { rutParticipante, observaciones } = req.body;
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const evento = await eventoRepository.findOneBy({ id });
    if (!evento) {
      return handleErrorClient(res, 404, "Evento deportivo no encontrado");
    }

    // Verificar si el evento requiere inscripción
    if (!evento.requiereInscripcion) {
      return handleErrorClient(res, 400, "Evento sin inscripción", 
        "Este evento no requiere inscripción previa");
    }

    // Verificar estado del evento
    if (evento.estado !== "programado") {
      return handleErrorClient(res, 400, "Evento no disponible", 
        "Solo se puede inscribir a eventos programados");
    }

    // Verificar fecha límite
    if (evento.fechaLimiteInscripcion && new Date() > new Date(evento.fechaLimiteInscripcion)) {
      return handleErrorClient(res, 400, "Inscripción cerrada", 
        "La fecha límite de inscripción ha pasado");
    }

    // Verificar cupo máximo
    if (evento.cupoMaximo && evento.inscritos >= evento.cupoMaximo) {
      return handleErrorClient(res, 400, "Cupo agotado", 
        "El evento ha alcanzado el cupo máximo");
    }

    // Determinar RUT del participante
    let rutFinal = rutParticipante || userRut;

    // Verificar autorización para inscribir a otros
    if (rutParticipante && rutParticipante !== userRut) {
      if (userRole === "apoderado") {
        // Verificar que sea su hijo
        const hijo = await userRepository.findOne({
          where: { rut: rutParticipante, rutApoderado: userRut }
        });
        if (!hijo) {
          return handleErrorClient(res, 403, "No autorizado", 
            "Solo puede inscribir a sus hijos");
        }
      } else if (!["entrenador", "directiva"].includes(userRole)) {
        return handleErrorClient(res, 403, "No autorizado");
      }
    }

    // Verificar que el participante existe
    const participante = await userRepository.findOneBy({ rut: rutFinal });
    if (!participante) {
      return handleErrorClient(res, 404, "Participante no encontrado");
    }

    // Verificar si ya está inscrito
    const inscripcionExistente = evento.participantes?.find(p => p.rut === rutFinal);
    if (inscripcionExistente) {
      return handleErrorClient(res, 400, "Ya inscrito", 
        "El participante ya está inscrito en este evento");
    }

    // Agregar participante
    if (!evento.participantes) {
      evento.participantes = [];
    }

    evento.participantes.push({
      rut: rutFinal,
      nombres: participante.nombres,
      apellidos: participante.apellidos,
      fechaInscripcion: new Date(),
      inscritoPorRut: userRut,
      observaciones,
      confirmado: false
    });

    evento.inscritos = evento.participantes.length;
    
    const eventoActualizado = await eventoRepository.save(evento);

    handleSuccess(res, 200, "Inscripción realizada exitosamente", {
      evento: eventoActualizado,
      participante: {
        rut: rutFinal,
        nombres: participante.nombres,
        apellidos: participante.apellidos
      }
    });

  } catch (error) {
    console.error("Error en inscripción:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Confirmar participación (Entrenador, Directiva)
export async function confirmarParticipacion(req, res) {
  try {
    const { id } = req.params;
    const { rutParticipante, confirmado } = req.body;
    const userRole = req.user.rol;

    if (!["entrenador", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const evento = await eventoRepository.findOneBy({ id });
    if (!evento) {
      return handleErrorClient(res, 404, "Evento deportivo no encontrado");
    }

    // Buscar participante
    const participanteIndex = evento.participantes?.findIndex(p => p.rut === rutParticipante);
    if (participanteIndex === -1) {
      return handleErrorClient(res, 404, "Participante no encontrado en el evento");
    }

    // Actualizar confirmación
    evento.participantes[participanteIndex].confirmado = confirmado;
    evento.participantes[participanteIndex].fechaConfirmacion = confirmado ? new Date() : null;

    const eventoActualizado = await eventoRepository.save(evento);

    handleSuccess(res, 200, `Participación ${confirmado ? 'confirmada' : 'no confirmada'} exitosamente`, 
      eventoActualizado);

  } catch (error) {
    console.error("Error confirmando participación:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener eventos por calendario
export async function obtenerCalendarioEventos(req, res) {
  try {
    const { mes, año } = req.query;

    if (!mes || !año) {
      return handleErrorClient(res, 400, "Parámetros requeridos", 
        "Mes y año son requeridos");
    }

    const fechaInicio = new Date(año, mes - 1, 1);
    const fechaFin = new Date(año, mes, 0);

    const eventos = await eventoRepository.find({
      where: {
        fechaInicio: {
          $gte: fechaInicio.toISOString().split('T')[0],
          $lte: fechaFin.toISOString().split('T')[0]
        }
      },
      relations: ["creadoPor"],
      order: { fechaInicio: "ASC", horaInicio: "ASC" }
    });

    // Agrupar eventos por día
    const eventosPorDia = eventos.reduce((acc, evento) => {
      const dia = new Date(evento.fechaInicio).getDate();
      if (!acc[dia]) {
        acc[dia] = [];
      }
      acc[dia].push(evento);
      return acc;
    }, {});

    handleSuccess(res, 200, "Calendario de eventos obtenido exitosamente", {
      mes: parseInt(mes),
      año: parseInt(año),
      totalEventos: eventos.length,
      eventosPorDia
    });

  } catch (error) {
    console.error("Error obteniendo calendario:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Eliminar evento deportivo (Solo Directiva)
export async function eliminarEventoDeportivo(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede eliminar eventos deportivos");
    }

    const evento = await eventoRepository.findOneBy({ id });
    if (!evento) {
      return handleErrorClient(res, 404, "Evento deportivo no encontrado");
    }

    // Verificar si el evento ya comenzó
    const ahora = new Date();
    const fechaInicioEvento = getEventStartDate(evento);
    if (fechaInicioEvento && fechaInicioEvento <= ahora) {
      return handleErrorClient(res, 400, "Evento iniciado", 
        "No se puede eliminar un evento que ya comenzó");
    }

    await eventoRepository.remove(evento);

    handleSuccess(res, 200, "Evento deportivo eliminado exitosamente");

  } catch (error) {
    console.error("Error eliminando evento:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
