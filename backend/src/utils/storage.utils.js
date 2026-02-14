"use strict";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { HOST, PORT, NODE_ENV } from "../config/configEnv.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Directorio base de uploads (backend/uploads)
const UPLOADS_DIR = path.resolve(__dirname, "..", "..", "uploads");

// Construir URL base del backend para archivos locales
function getBackendBaseUrl(req) {
  // 1. Usar variable de entorno explícita si existe (para producción)
  if (process.env.BACKEND_URL) {
    return process.env.BACKEND_URL.replace(/\/$/, '');
  }
  
  // 2. PRIORIDAD: Construir desde request (funciona en producción y desarrollo)
  if (req) {
    const protocol = req.protocol;
    const host = req.get("host");
    return `${protocol}://${host}`;
  }
  
  // 3. Fallback a configuración de entorno (solo si no hay request)
  const protocol = NODE_ENV === 'production' ? 'https' : 'http';
  return `${protocol}://${HOST}:${PORT}`;
}

/**
 * Construir URL completa para archivos locales
 * @param {string} value - Ruta del archivo (relativa o absoluta)
 * @param {Object} req - Objeto request de Express (opcional)
 * @returns {string|null} - URL completa del archivo
 */
export function resolveFileUrl(value, req) {
  if (!value) {
    return null;
  }

  // Si ya es una URL completa, devolverla tal cual
  if (/^https?:\/\//i.test(value)) {
    return value;
  }

  // Para archivos locales: construir URL completa
  const baseUrl = getBackendBaseUrl(req);
  const cleanPath = value.replace(/^\/+/, "");
  
  // Si la ruta no empieza con "uploads", agregarla
  if (!cleanPath.startsWith("uploads/")) {
    return `${baseUrl}/uploads/${cleanPath}`;
  }
  
  return `${baseUrl}/${cleanPath}`;
}

/**
 * Extraer la ruta del archivo desde una URL o path
 * @param {string} pathOrUrl - URL completa o ruta relativa
 * @returns {string|null} - Ruta relativa del archivo
 */
export function extractObjectKey(pathOrUrl) {
  if (!pathOrUrl) return null;
  
  // Si es una URL completa, extraer el path
  if (/^https?:\/\//i.test(pathOrUrl)) {
    try {
      const url = new URL(pathOrUrl);
      return decodeURIComponent(url.pathname.replace(/^\/+/, ""));
    } catch {
      return null;
    }
  }
  
  // Si es una ruta relativa, limpiarla
  return pathOrUrl.replace(/^\/+/, "");
}

/**
 * Eliminar archivo del almacenamiento local
 * @param {string} pathOrUrl - URL completa o ruta relativa del archivo
 * @returns {Promise<boolean>} - true si se eliminó correctamente
 */
export async function deleteFromStorage(pathOrUrl) {
  try {
    const relativePath = extractObjectKey(pathOrUrl);
    if (!relativePath) {
      console.warn("No se pudo extraer la ruta del archivo:", pathOrUrl);
      return false;
    }

    // Construir ruta absoluta
    const filePath = path.resolve(UPLOADS_DIR, relativePath.replace(/^uploads\//, ""));
    
    // Verificar que el archivo existe
    if (!fs.existsSync(filePath)) {
      console.warn("Archivo no encontrado:", filePath);
      return false;
    }

    // Eliminar archivo
    fs.unlinkSync(filePath);
    console.log("✅ Archivo eliminado:", relativePath);
    return true;
  } catch (error) {
    console.error("❌ Error al eliminar archivo:", error.message);
    return false;
  }
}

// Mantener alias por compatibilidad
export const deleteFromS3 = deleteFromStorage;
