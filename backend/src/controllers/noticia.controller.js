"use strict";
import {
  createNoticiaService,
  getNoticiasService,
  getNoticiaService,
  updateNoticiaService,
  deleteNoticiaService,
  changeEstadoNoticiaService,
  toggleDestacadaService,
} from "../services/noticia.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function createNoticia(req, res) {
  try {
    const noticiaData = req.body;
    const { rut, nombreCompleto } = req.user;

    // Validaciones básicas
    if (
      !noticiaData.titulo ||
      !noticiaData.descripcion ||
      !noticiaData.imagen
    ) {
      return handleErrorClient(
        res,
        400,
        "Título, descripción e imagen son obligatorios",
      );
    }

    // Agregar información del creador
    const dataWithCreator = {
      ...noticiaData,
      rutCreador: rut,
      nombreCreador: nombreCompleto,
    };

    const [noticia, error] = await createNoticiaService(dataWithCreator);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 201, "Noticia creada exitosamente", noticia);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getNoticias(req, res) {
  try {
    const { estado, destacada, fechaDesde, fechaHasta } = req.query;
    const { rol } = req.user || {};

    // Filtros según el rol (si hay usuario autenticado)
    const filters = {};

    if (estado) {
      filters.estado = estado;
    }

    if (destacada !== undefined) {
      filters.destacada = destacada === "true";
    }

    if (fechaDesde) {
      filters.fechaDesde = fechaDesde;
    }

    if (fechaHasta) {
      filters.fechaHasta = fechaHasta;
    }

    // Si no es directiva, solo mostrar noticias publicadas
    if (rol && rol !== "directiva") {
      filters.estado = "publicada";
    }

    const [noticias, error] = await getNoticiasService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Noticias encontradas", noticias);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

// Endpoint público para obtener noticias sin autenticación
export async function getNoticiasPublicas(req, res) {
  try {
    const { destacada, limite } = req.query;

    const filters = {
      estado: "publicada", // Solo noticias publicadas
    };

    if (destacada !== undefined) {
      filters.destacada = destacada === "true";
    }

    const [noticias, error] = await getNoticiasService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    // Limitar cantidad si se especifica
    let noticiasResult = noticias;
    if (limite && !isNaN(parseInt(limite))) {
      noticiasResult = noticias.slice(0, parseInt(limite));
    }

    handleSuccess(res, 200, "Noticias públicas encontradas", noticiasResult);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getNoticia(req, res) {
  try {
    const { id } = req.params;
    const { rol } = req.user || {};

    if (!id) {
      return handleErrorClient(res, 400, "ID de la noticia es obligatorio");
    }

    const [noticia, error] = await getNoticiaService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    // Si no es directiva, solo puede ver noticias publicadas
    if (rol && rol !== "directiva" && noticia.estado !== "publicada") {
      return handleErrorClient(
        res,
        403,
        "No tienes permisos para ver esta noticia",
      );
    }

    handleSuccess(res, 200, "Noticia encontrada", noticia);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateNoticia(req, res) {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!id) {
      return handleErrorClient(res, 400, "ID de la noticia es obligatorio");
    }

    const [noticia, error] = await updateNoticiaService(id, updateData);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Noticia actualizada exitosamente", noticia);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteNoticia(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return handleErrorClient(res, 400, "ID de la noticia es obligatorio");
    }

    const [result, error] = await deleteNoticiaService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Noticia eliminada exitosamente", result);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function changeEstadoNoticia(req, res) {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!id) {
      return handleErrorClient(res, 400, "ID de la noticia es obligatorio");
    }

    if (!estado) {
      return handleErrorClient(res, 400, "Estado es obligatorio");
    }

    const [noticia, error] = await changeEstadoNoticiaService(id, estado);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(
      res,
      200,
      `Estado de la noticia cambiado a '${estado}' exitosamente`,
      noticia,
    );
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function toggleDestacada(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return handleErrorClient(res, 400, "ID de la noticia es obligatorio");
    }

    const [noticia, error] = await toggleDestacadaService(id);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    const estado = noticia.destacada ? "destacada" : "no destacada";
    handleSuccess(
      res,
      200,
      `Noticia marcada como ${estado} exitosamente`,
      noticia,
    );
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}
