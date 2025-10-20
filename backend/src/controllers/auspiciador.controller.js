"use strict";
import {
  createAuspiciadorService,
  getAuspiciadoresService,
  getAuspiciadorService,
  updateAuspiciadorService,
  deleteAuspiciadorService,
  changeEstadoAuspiciadorService,
} from "../services/auspiciador.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function createAuspiciador(req, res) {
  try {
    const auspiciadorData = req.body;
    const { rut, nombreCompleto } = req.user;

    // Validaciones básicas
    if (!auspiciadorData.titulo || !auspiciadorData.imagen) {
      return handleErrorClient(res, 400, "Título e imagen son obligatorios");
    }

    // Agregar información del creador
    const dataWithCreator = {
      ...auspiciadorData,
      rutCreador: rut,
      nombreCreador: nombreCompleto,
    };

    const [auspiciador, error] = await createAuspiciadorService(dataWithCreator);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 201, "Auspiciador creado exitosamente", auspiciador);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getAuspiciadores(req, res) {
  try {
    const { estado } = req.query;
    const { rol } = req.user || {};

    // Filtros según el rol (si hay usuario autenticado)
    const filters = {};
    
    if (estado) {
      filters.estado = estado;
    }

    // Si no es directiva, solo mostrar auspiciadores activos
    if (rol && rol !== "directiva") {
      filters.estado = "activo";
    }

    const [auspiciadores, error] = await getAuspiciadoresService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Auspiciadores encontrados", auspiciadores);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

// Endpoint público para obtener auspiciadores sin autenticación
export async function getAuspiciadoresPublicos(req, res) {
  try {
    const filters = {
      estado: "activo", // Solo auspiciadores activos
    };

    const [auspiciadores, error] = await getAuspiciadoresService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Auspiciadores públicos encontrados", auspiciadores);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getAuspiciador(req, res) {
  try {
    const { id } = req.params;
    const { rol } = req.user || {};

    if (!id) {
      return handleErrorClient(res, 400, "ID del auspiciador es obligatorio");
    }

    const [auspiciador, error] = await getAuspiciadorService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    // Si no es directiva, solo puede ver auspiciadores activos
    if (rol && rol !== "directiva" && auspiciador.estado !== "activo") {
      return handleErrorClient(res, 403, "No tienes permisos para ver este auspiciador");
    }

    handleSuccess(res, 200, "Auspiciador encontrado", auspiciador);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateAuspiciador(req, res) {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!id) {
      return handleErrorClient(res, 400, "ID del auspiciador es obligatorio");
    }

    const [auspiciador, error] = await updateAuspiciadorService(id, updateData);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Auspiciador actualizado exitosamente", auspiciador);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteAuspiciador(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return handleErrorClient(res, 400, "ID del auspiciador es obligatorio");
    }

    const [result, error] = await deleteAuspiciadorService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Auspiciador eliminado exitosamente", result);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function changeEstadoAuspiciador(req, res) {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!id) {
      return handleErrorClient(res, 400, "ID del auspiciador es obligatorio");
    }

    if (!estado) {
      return handleErrorClient(res, 400, "Estado es obligatorio");
    }

    const [auspiciador, error] = await changeEstadoAuspiciadorService(id, estado);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 200, `Estado del auspiciador cambiado a '${estado}' exitosamente`, auspiciador);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}