"use strict";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { resolveFileUrl, deleteFromS3, extractObjectKey } from "../utils/storage.utils.js";

export async function uploadImagen(req, res) {
  try {
    if (!req.file?.location) {
      return handleErrorClient(res, 400, "Archivo requerido", "Debes adjuntar una imagen válida.");
    }

    const payload = {
      key: req.file.key,
      url: resolveFileUrl(req.file.location),
      size: req.file.size,
      mimeType: req.file.mimetype,
      originalName: req.file.originalname,
    };

    handleSuccess(res, 201, "Imagen subida exitosamente", payload);
  } catch (error) {
    console.error("Error subiendo imagen:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function getImagen(req, res) {
  try {
    const { key } = req.params;
    const publicUrl = resolveFileUrl(key, req);
    if (!publicUrl) {
      return handleErrorClient(res, 404, "Recurso no encontrado");
    }
    res.redirect(publicUrl);
  } catch (error) {
    console.error("Error obteniendo imagen:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function deleteImagen(req, res) {
  try {
    const { key } = req.params;
    const objectKey = extractObjectKey(key);
    if (!objectKey) {
      return handleErrorClient(res, 400, "Identificador de archivo inválido");
    }

    await deleteFromS3(objectKey);
    handleSuccess(res, 200, "Imagen eliminada exitosamente", { key: objectKey });
  } catch (error) {
    console.error("Error eliminando imagen:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
