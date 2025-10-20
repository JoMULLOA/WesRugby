"use strict";
import {
  createActaReunionService,
  getActasReunionService,
  getActaReunionService,
  updateActaReunionService,
  deleteActaReunionService,
  changeEstadoActaService,
} from "../services/actaReunion.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function createActaReunion(req, res) {
  try {
    const actaData = req.body;
    const { rut, nombreCompleto } = req.user;

    // Validaciones básicas
    if (!actaData.titulo || !actaData.fecha || !actaData.descripcion) {
      return handleErrorClient(res, 400, "Título, fecha y descripción son obligatorios");
    }

    // Agregar información del creador
    const dataWithCreator = {
      ...actaData,
      rutCreador: rut,
      nombreCreador: nombreCompleto,
    };

    const [acta, error] = await createActaReunionService(dataWithCreator);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 201, "Acta de reunión creada exitosamente", acta);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getActasReunion(req, res) {
  try {
    const { estado, fechaDesde, fechaHasta } = req.query;
    const { rol } = req.user;

    // Filtros según el rol
    const filters = {};
    
    if (estado) {
      filters.estado = estado;
    }
    
    if (fechaDesde) {
      filters.fechaDesde = fechaDesde;
    }
    
    if (fechaHasta) {
      filters.fechaHasta = fechaHasta;
    }

    // Los apoderados solo pueden ver actas publicadas
    if (rol === "apoderado") {
      filters.estado = "publicada";
    }

    const [actas, error] = await getActasReunionService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    if (!actas || actas.length === 0) {
      return handleSuccess(res, 200, "No hay actas de reunión disponibles", []);
    }

    handleSuccess(res, 200, "Actas de reunión encontradas", actas);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getActaReunion(req, res) {
  try {
    const { id } = req.params;
    const { rol } = req.user;

    if (!id) {
      return handleErrorClient(res, 400, "ID del acta es obligatorio");
    }

    const [acta, error] = await getActaReunionService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    // Los apoderados solo pueden ver actas publicadas
    if (rol === "apoderado" && acta.estado !== "publicada") {
      return handleErrorClient(res, 403, "No tienes permisos para ver este acta");
    }

    handleSuccess(res, 200, "Acta de reunión encontrada", acta);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateActaReunion(req, res) {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const { rut, rol } = req.user;

    if (!id) {
      return handleErrorClient(res, 400, "ID del acta es obligatorio");
    }

    // Solo la directiva puede editar actas
    if (rol !== "directiva") {
      return handleErrorClient(res, 403, "Solo la directiva puede editar actas de reunión");
    }

    // Verificar que el acta existe y obtener datos actuales
    const [actaExistente, getError] = await getActaReunionService(id);
    if (getError) {
      return handleErrorClient(res, 404, getError);
    }

    // Solo el creador puede editar el acta (opcional, puedes remover esta validación)
    if (actaExistente.rutCreador !== rut) {
      return handleErrorClient(res, 403, "Solo el creador del acta puede editarla");
    }

    const [acta, error] = await updateActaReunionService(id, updateData);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Acta de reunión actualizada exitosamente", acta);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteActaReunion(req, res) {
  try {
    const { id } = req.params;
    const { rut, rol } = req.user;

    if (!id) {
      return handleErrorClient(res, 400, "ID del acta es obligatorio");
    }

    // Solo la directiva puede eliminar actas
    if (rol !== "directiva") {
      return handleErrorClient(res, 403, "Solo la directiva puede eliminar actas de reunión");
    }

    // Verificar que el acta existe
    const [actaExistente, getError] = await getActaReunionService(id);
    if (getError) {
      return handleErrorClient(res, 404, getError);
    }

    // Solo el creador puede eliminar el acta (opcional)
    if (actaExistente.rutCreador !== rut) {
      return handleErrorClient(res, 403, "Solo el creador del acta puede eliminarla");
    }

    const [result, error] = await deleteActaReunionService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Acta de reunión eliminada exitosamente", result);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function changeEstadoActa(req, res) {
  try {
    const { id } = req.params;
    const { estado } = req.body;
    const { rol } = req.user;

    if (!id) {
      return handleErrorClient(res, 400, "ID del acta es obligatorio");
    }

    if (!estado) {
      return handleErrorClient(res, 400, "Estado es obligatorio");
    }

    // Solo la directiva puede cambiar el estado
    if (rol !== "directiva") {
      return handleErrorClient(res, 403, "Solo la directiva puede cambiar el estado del acta");
    }

    const [acta, error] = await changeEstadoActaService(id, estado);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 200, `Estado del acta cambiado a '${estado}' exitosamente`, acta);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}