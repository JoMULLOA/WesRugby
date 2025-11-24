"use strict";
import { DeleteObjectCommand } from "@aws-sdk/client-s3";
import { s3Client } from "../config/s3.js";
import { HOST, PORT } from "../config/configEnv.js";

const bucket = process.env.S3_BUCKET;
const region = process.env.S3_REGION;
const publicBase =
  process.env.S3_PUBLIC_URL ||
  (bucket && region ? `https://${bucket}.s3.${region}.amazonaws.com` : null);

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
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http';
  return `${protocol}://${HOST}:${PORT}`;
}

export function resolveFileUrl(value, req) {
  if (!value) {
    return null;
  }

  // Si ya es una URL completa, devolverla tal cual
  if (/^https?:\/\//i.test(value)) {
    return value;
  }

  // Si hay S3 configurado, construir URL de S3
  if (publicBase) {
    return `${publicBase}/${value.replace(/^\/+/, "")}`;
  }

  // Para archivos locales: devolver solo la ruta relativa
  // El frontend construirá la URL completa usando su configuración
  return value;
}

export function extractObjectKey(pathOrUrl) {
  if (!pathOrUrl) return null;
  if (/^https?:\/\//i.test(pathOrUrl)) {
    try {
      const url = new URL(pathOrUrl);
      return decodeURIComponent(url.pathname.replace(/^\/+/, ""));
    } catch {
      return null;
    }
  }
  return pathOrUrl.replace(/^\/+/, "");
}

export async function deleteFromS3(pathOrUrl) {
  try {
    const key = extractObjectKey(pathOrUrl);
    if (!key || !bucket) {
      return;
    }
    await s3Client.send(
      new DeleteObjectCommand({
        Bucket: bucket,
        Key: key,
      }),
    );
  } catch (error) {
    console.warn("No se pudo eliminar archivo remoto:", error.message);
  }
}
