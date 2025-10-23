"use strict";
import fs from "fs";
import path from "path";
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

const uploadsRoot = path.resolve("uploads");

function toRelativeUploadPath(absolutePath) {
  if (!absolutePath) {
    throw new Error("Ruta de archivo inválida");
  }

  const normalizedAbsolute = path.resolve(absolutePath);

  if (!normalizedAbsolute.startsWith(uploadsRoot)) {
    throw new Error("Ruta de archivo fuera del directorio permitido");
  }

  return path.relative(uploadsRoot, normalizedAbsolute).replace(/\\/g, "/");
}

function buildUploadUrl(req, relativePath) {
  const normalized = relativePath.replace(/\\/g, "/").replace(/^\/+/, "");
  return `${req.protocol}://${req.get("host")}/uploads/${normalized}`;
}

function deleteUploadFile(relativePath) {
  if (!relativePath) {
    return;
  }

  const sanitized = relativePath.replace(/\\/g, "/").replace(/^\/+/, "");
  const absolute = path.resolve(uploadsRoot, sanitized);

  if (!absolute.startsWith(uploadsRoot)) {
    return;
  }

  if (fs.existsSync(absolute)) {
    try {
      fs.unlinkSync(absolute);
    } catch (error) {
      console.warn("No se pudo eliminar el archivo en uploads:", error.message);
    }
  }
}

function deleteUploadedFileFromRequest(file) {
  if (!file?.path) {
    return;
  }

  try {
    const relative = toRelativeUploadPath(file.path);
    deleteUploadFile(relative);
  } catch (error) {
    if (fs.existsSync(file.path)) {
      try {
        fs.unlinkSync(file.path);
      } catch (unlinkError) {
        console.warn("No se pudo limpiar el archivo temporal:", unlinkError.message);
      }
    }
  }
}

function normalizeUploadsPath(rawPath) {
  if (!rawPath) {
    return null;
  }

  const sanitized = rawPath.replace(/\\/g, "/");

  if (sanitized.startsWith("/uploads/") || sanitized.startsWith("uploads/")) {
    return sanitized.replace(/^\/?uploads\//, "");
  }

  return null;
}

function extractUploadsRelativePath(value) {
  if (!value) {
    return null;
  }

  const raw = String(value).trim();

  if (!raw) {
    return null;
  }

  if (raw.includes("://")) {
    try {
      const parsed = new URL(raw);
      return normalizeUploadsPath(parsed.pathname);
    } catch {
      return null;
    }
  }

  return normalizeUploadsPath(raw);
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

function mapAuspiciadorForResponse(entity, req) {
  if (!entity) {
    return entity;
  }

  const plain = { ...entity };
  const relativePath = extractUploadsRelativePath(plain.imagen);

  if (relativePath) {
    plain.imagen = buildUploadUrl(req, relativePath);
  }

  return plain;
}

function mapAuspiciadoresCollection(collection, req) {
  if (!collection) {
    return collection;
  }

  if (Array.isArray(collection)) {
    return collection.map((item) => mapAuspiciadorForResponse(item, req));
  }

  return mapAuspiciadorForResponse(collection, req);
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

    let uploadedRelativePath = null;

    if (req.file) {
      uploadedRelativePath = toRelativeUploadPath(req.file.path);
      auspiciadorData.imagen = uploadedRelativePath;
    } else if (typeof auspiciadorData.imagen === "string") {
      auspiciadorData.imagen = auspiciadorData.imagen.trim();
    }

    if (typeof auspiciadorData.titulo === "string") {
      auspiciadorData.titulo = auspiciadorData.titulo.trim();
    }

    if (!auspiciadorData.titulo) {
      deleteUploadFile(uploadedRelativePath);
      return handleErrorClient(res, 400, "Título es obligatorio");
    }

    if (!auspiciadorData.imagen) {
      deleteUploadFile(uploadedRelativePath);
      return handleErrorClient(res, 400, "La imagen es obligatoria");
    }

    const dataWithCreator = {
      ...auspiciadorData,
      rutCreador: rut,
      nombreCreador: nombreCompleto || "",
    };

    const [auspiciador, error] = await createAuspiciadorService(dataWithCreator);

    if (error) {
      deleteUploadFile(uploadedRelativePath);
      return handleErrorClient(res, 400, error);
    }

    const responseData = mapAuspiciadorForResponse(auspiciador, req);
    handleSuccess(res, 201, "Auspiciador creado exitosamente", responseData);
  } catch (error) {
    deleteUploadedFileFromRequest(req.file);
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

    const responseData = mapAuspiciadoresCollection(auspiciadores, req);
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

    const responseData = mapAuspiciadoresCollection(auspiciadores, req);
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

    const responseData = mapAuspiciadorForResponse(auspiciador, req);
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
      deleteUploadedFileFromRequest(req.file);
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

    let newRelativePath = null;

    if (req.file) {
      newRelativePath = toRelativeUploadPath(req.file.path);
      updateData.imagen = newRelativePath;
    } else if (typeof updateData.imagen === "string") {
      updateData.imagen = updateData.imagen.trim();

      if (!updateData.imagen) {
        delete updateData.imagen;
      }
    }

    const [existing, existingError] = await getAuspiciadorService(id);

    if (existingError || !existing) {
      if (newRelativePath) {
        deleteUploadFile(newRelativePath);
      } else {
        deleteUploadedFileFromRequest(req.file);
      }

      return handleErrorClient(res, 404, existingError || "Auspiciador no encontrado");
    }

    const previousRelativePath = extractUploadsRelativePath(existing.imagen);

    const [auspiciador, error] = await updateAuspiciadorService(id, updateData);

    if (error) {
      if (newRelativePath) {
        deleteUploadFile(newRelativePath);
      } else {
        deleteUploadedFileFromRequest(req.file);
      }

      return handleErrorClient(res, 404, error);
    }

    if (newRelativePath && previousRelativePath && previousRelativePath !== newRelativePath) {
      deleteUploadFile(previousRelativePath);
    }

    const responseData = mapAuspiciadorForResponse(auspiciador, req);
    handleSuccess(res, 200, "Auspiciador actualizado exitosamente", responseData);
  } catch (error) {
    deleteUploadedFileFromRequest(req.file);
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

    const previousRelativePath = extractUploadsRelativePath(existing.imagen);

    const [result, error] = await deleteAuspiciadorService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    if (previousRelativePath) {
      deleteUploadFile(previousRelativePath);
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

    const responseData = mapAuspiciadorForResponse(auspiciador, req);
    handleSuccess(res, 200, `Estado del auspiciador cambiado a '${estado}' exitosamente`, responseData);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}