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
import { resolveFileUrl, deleteFromS3 } from "../utils/storage.utils.js";

async function cleanupUploadedAsset(file) {
  if (file?.location) {
    await deleteFromS3(file.location);
  }
}

function formatOrden(value) {
  if (value === undefined || value === null) {
    return undefined;
  }

  const parsed = Number(value);

  if (Number.isNaN(parsed)) {
    return undefined;
  }

  return parsed;
}

function mapAuspiciadorForResponse(entity) {
  if (!entity) {
    return entity;
  }

  const plain = { ...entity };
  plain.imagen = resolveFileUrl(plain.imagen);
  return plain;
}

function mapAuspiciadoresCollection(collection) {
  if (!collection) {
    return collection;
  }

  if (Array.isArray(collection)) {
    return collection.map((item) => mapAuspiciadorForResponse(item));
  }

  return mapAuspiciadorForResponse(collection);
}

export async function createAuspiciador(req, res) {
  try {
    const auspiciadorData = { ...req.body };
    const { rut, nombreCompleto } = req.user;

    if (typeof auspiciadorData.enlace === "string" && !auspiciadorData.sitioWeb) {
      auspiciadorData.sitioWeb = auspiciadorData.enlace.trim();
    }

    if ("enlace" in auspiciadorData) {
      delete auspiciadorData.enlace;
    }

    const parsedOrden = formatOrden(auspiciadorData.orden);

    if (parsedOrden !== undefined) {
      auspiciadorData.orden = parsedOrden;
    } else {
      delete auspiciadorData.orden;
    }
    const uploadedUrl = req.file?.location || null;
    if (uploadedUrl) {
      auspiciadorData.imagen = uploadedUrl;
    } else if (typeof auspiciadorData.imagen === "string") {
      auspiciadorData.imagen = auspiciadorData.imagen.trim();
    }

    if (typeof auspiciadorData.titulo === "string") {
      auspiciadorData.titulo = auspiciadorData.titulo.trim();
    }

    if (!auspiciadorData.titulo) {
      await cleanupUploadedAsset(req.file);
      return handleErrorClient(res, 400, "Título es obligatorio");
    }

    if (!auspiciadorData.imagen) {
      await cleanupUploadedAsset(req.file);
      return handleErrorClient(res, 400, "La imagen es obligatoria");
    }

    const dataWithCreator = {
      ...auspiciadorData,
      rutCreador: rut,
      nombreCreador: nombreCompleto || "",
    };

    const [auspiciador, error] = await createAuspiciadorService(dataWithCreator);

    if (error) {
      await cleanupUploadedAsset(req.file);
      return handleErrorClient(res, 400, error);
    }

    const responseData = mapAuspiciadorForResponse(auspiciador);
    handleSuccess(res, 201, "Auspiciador creado exitosamente", responseData);
  } catch (error) {
    await cleanupUploadedAsset(req.file);
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

    const responseData = mapAuspiciadoresCollection(auspiciadores);
    handleSuccess(res, 200, "Auspiciadores encontrados", responseData);
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

    const responseData = mapAuspiciadoresCollection(auspiciadores);
    handleSuccess(res, 200, "Auspiciadores públicos encontrados", responseData);
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

    const responseData = mapAuspiciadorForResponse(auspiciador);
    handleSuccess(res, 200, "Auspiciador encontrado", responseData);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateAuspiciador(req, res) {
  try {
    const { id } = req.params;
    const updateData = { ...req.body };

    if (!id) {
      await cleanupUploadedAsset(req.file);
      return handleErrorClient(res, 400, "ID del auspiciador es obligatorio");
    }

    if (typeof updateData.enlace === "string" && !updateData.sitioWeb) {
      updateData.sitioWeb = updateData.enlace.trim();
    }

    if ("enlace" in updateData) {
      delete updateData.enlace;
    }

    const parsedOrden = formatOrden(updateData.orden);

    if (parsedOrden !== undefined) {
      updateData.orden = parsedOrden;
    } else {
      delete updateData.orden;
    }

    if (typeof updateData.titulo === "string") {
      updateData.titulo = updateData.titulo.trim();

      if (!updateData.titulo) {
        delete updateData.titulo;
      }
    }

    let newImageUrl = null;

    if (req.file) {
      newImageUrl = req.file.location;
      updateData.imagen = newImageUrl;
    } else if (typeof updateData.imagen === "string") {
      updateData.imagen = updateData.imagen.trim();

      if (!updateData.imagen) {
        delete updateData.imagen;
      }
    }

    const [existing, existingError] = await getAuspiciadorService(id);

    if (existingError || !existing) {
      await cleanupUploadedAsset(req.file);
      return handleErrorClient(res, 404, existingError || "Auspiciador no encontrado");
    }

    const previousImageUrl = existing.imagen;

    const [auspiciador, error] = await updateAuspiciadorService(id, updateData);

    if (error) {
      await cleanupUploadedAsset(req.file);
      return handleErrorClient(res, 404, error);
    }

    if (newImageUrl && previousImageUrl && previousImageUrl !== newImageUrl) {
      await deleteFromS3(previousImageUrl);
    }

    const responseData = mapAuspiciadorForResponse(auspiciador);
    handleSuccess(res, 200, "Auspiciador actualizado exitosamente", responseData);
  } catch (error) {
    await cleanupUploadedAsset(req.file);
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteAuspiciador(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return handleErrorClient(res, 400, "ID del auspiciador es obligatorio");
    }

    const [existing, existingError] = await getAuspiciadorService(id);

    if (existingError || !existing) {
      return handleErrorClient(res, 404, existingError || "Auspiciador no encontrado");
    }

    const previousImageUrl = existing.imagen;

    const [result, error] = await deleteAuspiciadorService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    if (previousImageUrl) {
      await deleteFromS3(previousImageUrl);
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

    const responseData = mapAuspiciadorForResponse(auspiciador);
    handleSuccess(res, 200, `Estado del auspiciador cambiado a '${estado}' exitosamente`, responseData);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}
