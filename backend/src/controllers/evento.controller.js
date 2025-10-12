"use strict";
import { AppDataSource } from "../config/configDb.js";
import Evento from "../entity/evento.entity.js";
import ParticipacionEvento from "../entity/participacionEvento.entity.js";
import User from "../entity/user.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

// Crear un nuevo evento (solo directiva)
export async function crearEvento(req, res) {
  try {
    const { nombre, fecha, descripcion } = req.body;

    if (!nombre || !fecha) {
      return handleErrorClient(
        res,
        400,
        "Faltan campos obligatorios",
        "Nombre y fecha son requeridos"
      );
    }

    const eventoRepository = AppDataSource.getRepository(Evento);

    const nuevoEvento = eventoRepository.create({
      nombre,
      fecha: new Date(fecha),
      descripcion: descripcion || null,
      estado: "activo",
    });

    const eventoGuardado = await eventoRepository.save(nuevoEvento);

    handleSuccess(res, 201, "Evento creado exitosamente", eventoGuardado);
  } catch (error) {
    console.error("Error al crear evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener todos los eventos (directiva)
export async function obtenerEventos(req, res) {
  try {
    const eventoRepository = AppDataSource.getRepository(Evento);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);

    const eventos = await eventoRepository.find({
      order: { createdAt: "DESC" },
    });

    // Agregar conteo de participaciones a cada evento
    const eventosConParticipaciones = await Promise.all(
      eventos.map(async (evento) => {
        const participaciones = await participacionRepository.count({
          where: { eventoId: evento.id }
        });
        return {
          ...evento,
          totalParticipaciones: participaciones
        };
      })
    );

    handleSuccess(res, 200, "Eventos obtenidos exitosamente", eventosConParticipaciones);
  } catch (error) {
    console.error("Error al obtener eventos:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener eventos disponibles para participación (RamaExterna)
export async function obtenerEventosDisponibles(req, res) {
  try {
    const eventoRepository = AppDataSource.getRepository(Evento);

    const eventos = await eventoRepository.find({
      where: { estado: "activo" },
      order: { fecha: "ASC" },
    });

    handleSuccess(res, 200, "Eventos disponibles obtenidos exitosamente", eventos);
  } catch (error) {
    console.error("Error al obtener eventos disponibles:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Participar en un evento (RamaExterna)
export async function participarEnEvento(req, res) {
  try {
    const { eventoId, cantidadNinos, categoria, listaInvitados } = req.body;
    const rutRamaExterna = req.user.rut;

    if (!eventoId || !cantidadNinos || !categoria) {
      return handleErrorClient(
        res,
        400,
        "Faltan campos obligatorios",
        "ID del evento, cantidad de niños y categoría son requeridos"
      );
    }

    const eventoRepository = AppDataSource.getRepository(Evento);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);

    // Verificar que el evento existe y está activo
    const evento = await eventoRepository.findOne({
      where: { id: eventoId, estado: "activo" }
    });

    if (!evento) {
      return handleErrorClient(
        res,
        404,
        "Error al participar",
        "El evento no existe o no está disponible"
      );
    }

    // Verificar si ya existe participación
    const participacionExistente = await participacionRepository.findOne({
      where: { eventoId, rutRamaExterna }
    });

    if (participacionExistente) {
      return handleErrorClient(
        res,
        400,
        "Error al participar",
        "Ya tienes una participación registrada en este evento"
      );
    }

    const nuevaParticipacion = participacionRepository.create({
      eventoId,
      rutRamaExterna,
      cantidadNinos,
      categoria,
      listaInvitados: listaInvitados || null,
    });

    const participacionGuardada = await participacionRepository.save(nuevaParticipacion);

    handleSuccess(res, 201, "Participación registrada exitosamente", participacionGuardada);
  } catch (error) {
    console.error("Error al registrar participación:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener mis participaciones (RamaExterna)
export async function obtenerMisParticipacionesEvento(req, res) {
  try {
    const rutRamaExterna = req.user.rut;
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);
    const eventoRepository = AppDataSource.getRepository(Evento);

    const participaciones = await participacionRepository.find({
      where: { rutRamaExterna },
      order: { createdAt: "DESC" },
    });

    // Obtener información de los eventos
    const participacionesConEventos = await Promise.all(
      participaciones.map(async (participacion) => {
        const evento = await eventoRepository.findOne({
          where: { id: participacion.eventoId }
        });
        return {
          ...participacion,
          evento
        };
      })
    );

    handleSuccess(res, 200, "Participaciones obtenidas exitosamente", participacionesConEventos);
  } catch (error) {
    console.error("Error al obtener participaciones:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Actualizar evento (directiva)
export async function actualizarEvento(req, res) {
  try {
    const { id } = req.params;
    const { nombre, fecha, descripcion, estado } = req.body;

    const eventoRepository = AppDataSource.getRepository(Evento);

    const evento = await eventoRepository.findOne({ where: { id: parseInt(id) } });

    if (!evento) {
      return handleErrorClient(res, 404, "Evento no encontrado");
    }

    // Actualizar campos si se proporcionan
    if (nombre) evento.nombre = nombre;
    if (fecha) evento.fecha = new Date(fecha);
    if (descripcion !== undefined) evento.descripcion = descripcion;
    if (estado) evento.estado = estado;

    const eventoActualizado = await eventoRepository.save(evento);

    handleSuccess(res, 200, "Evento actualizado exitosamente", eventoActualizado);
  } catch (error) {
    console.error("Error al actualizar evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Eliminar evento (directiva)
export async function eliminarEvento(req, res) {
  try {
    const { id } = req.params;

    const eventoRepository = AppDataSource.getRepository(Evento);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);

    const evento = await eventoRepository.findOne({ where: { id: parseInt(id) } });

    if (!evento) {
      return handleErrorClient(res, 404, "Evento no encontrado");
    }

    // Verificar si hay participaciones
    const participaciones = await participacionRepository.count({
      where: { eventoId: parseInt(id) }
    });

    if (participaciones > 0) {
      return handleErrorClient(
        res,
        400,
        "No se puede eliminar el evento",
        "El evento tiene participaciones registradas. Cámbialo a estado 'cancelado' en su lugar."
      );
    }

    await eventoRepository.remove(evento);

    handleSuccess(res, 200, "Evento eliminado exitosamente");
  } catch (error) {
    console.error("Error al eliminar evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener participaciones de un evento (directiva)
export async function obtenerParticipacionesEvento(req, res) {
  try {
    const { id } = req.params;

    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);
    const userRepository = AppDataSource.getRepository(User);

    const participaciones = await participacionRepository.find({
      where: { eventoId: parseInt(id) },
      order: { createdAt: "DESC" },
    });

    // Obtener información de los usuarios
    const participacionesConUsuarios = await Promise.all(
      participaciones.map(async (participacion) => {
        const usuario = await userRepository.findOne({
          where: { rut: participacion.rutRamaExterna }
        });
        return {
          ...participacion,
          ramaExterna: usuario
        };
      })
    );

    handleSuccess(res, 200, "Participaciones del evento obtenidas exitosamente", participacionesConUsuarios);
  } catch (error) {
    console.error("Error al obtener participaciones del evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}