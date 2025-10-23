"use strict";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { optimizeImageBuffer } from "../utils/image.utils.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Directorio donde se guardan las imágenes
const UPLOADS_DIR = path.join(__dirname, '../../uploads/imagenes');

// Crear directorio si no existe
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Subir imagen
export async function uploadImagen(req, res) {
  try {
    const { filename, fileData, mimeType } = req.body;

    if (!filename || !fileData || !mimeType) {
      return handleErrorClient(res, 400, "Faltan datos requeridos", {
        requeridos: ["filename", "fileData", "mimeType"]
      });
    }

    // Validar tipo de archivo
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedTypes.includes(mimeType)) {
      return handleErrorClient(res, 400, "Tipo de archivo no permitido", {
        permitidos: allowedTypes
      });
    }

    // Generar nombre único para el archivo
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(2, 15);
    const extension = filename.split('.').pop();
    const uniqueFilename = `${timestamp}_${randomString}.${extension}`;

    // Convertir base64 a buffer
    let buffer;
    try {
      // Si fileData viene como base64 con prefijo data:image/...;base64,
      const base64Data = fileData.includes(',') ? fileData.split(',')[1] : fileData;
      buffer = Buffer.from(base64Data, 'base64');
    } catch (error) {
      return handleErrorClient(res, 400, "Formato de archivo inválido");
    }

    try {
      const optimization = await optimizeImageBuffer(buffer, mimeType, {
        maxWidth: 1400,
        maxHeight: 1400,
        quality: 80,
      });

      if (optimization?.buffer) {
        buffer = optimization.buffer;
      }
    } catch (error) {
      return handleErrorServer(res, 500, "Error procesando la imagen", error.message);
    }

    // Validar tamaño del archivo (5MB máximo) después de optimizar
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (buffer.length > maxSize) {
      return handleErrorClient(res, 400, "El archivo es muy grande", {
        tamaño_actual: `${(buffer.length / 1024 / 1024).toFixed(2)}MB`,
        tamaño_máximo: "5MB"
      });
    }

    // Guardar archivo
    const filePath = path.join(UPLOADS_DIR, uniqueFilename);
    fs.writeFileSync(filePath, buffer);

    // Construir URL de acceso (corregir ruta)
    const fileUrl = `/api/upload/imagen/${uniqueFilename}`;

    handleSuccess(res, 201, "Imagen subida exitosamente", {
      filename: uniqueFilename,
      originalName: filename,
      url: fileUrl,
      size: buffer.length,
      mimeType: mimeType
    });

  } catch (error) {
    console.error("Error subiendo imagen:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener imagen
export async function getImagen(req, res) {
  try {
    const { filename } = req.params;

    if (!filename) {
      return handleErrorClient(res, 400, "Nombre de archivo requerido");
    }

    const filePath = path.join(UPLOADS_DIR, filename);

    if (!fs.existsSync(filePath)) {
      return handleErrorClient(res, 404, "Archivo no encontrado");
    }

    // Detectar tipo MIME basado en la extensión
    const extension = path.extname(filename).toLowerCase();
    let mimeType = 'application/octet-stream';
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        mimeType = 'image/jpeg';
        break;
      case '.png':
        mimeType = 'image/png';
        break;
      case '.gif':
        mimeType = 'image/gif';
        break;
      case '.webp':
        mimeType = 'image/webp';
        break;
    }

    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'public, max-age=31536000'); // Cache por 1 año
    
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);

  } catch (error) {
    console.error("Error obteniendo imagen:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Eliminar imagen
export async function deleteImagen(req, res) {
  try {
    const { filename } = req.params;

    if (!filename) {
      return handleErrorClient(res, 400, "Nombre de archivo requerido");
    }

    const filePath = path.join(UPLOADS_DIR, filename);

    if (!fs.existsSync(filePath)) {
      return handleErrorClient(res, 404, "Archivo no encontrado");
    }

    // Eliminar archivo
    fs.unlinkSync(filePath);

    handleSuccess(res, 200, "Imagen eliminada exitosamente", {
      filename: filename
    });

  } catch (error) {
    console.error("Error eliminando imagen:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}