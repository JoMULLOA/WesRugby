"use strict";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Directorio base de uploads
const UPLOADS_DIR = path.resolve(__dirname, "..", "..", "uploads");

// Asegurar que existe el directorio de uploads
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

function sanitizeFileName(name = "") {
  return name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, "_")
    .replace(/[^\w.\-]/g, "")
    .toLowerCase();
}

/**
 * Crea un middleware de multer para almacenamiento local de archivos.
 * Los archivos se guardan en backend/uploads/{prefix}/
 * y se agrega el campo 'location' a req.file para compatibilidad con código S3.
 * 
 * @param {string} prefix - Prefijo de subdirectorio (ej: "avatars", "eventos")
 * @param {object} options - Opciones de configuración
 * @param {number} options.fileSize - Tamaño máximo del archivo en bytes (default: 5MB)
 * @returns {object} Objeto multer con método .single() que normaliza req.file.location
 */
export function createS3Uploader(prefix = "", { fileSize = 5 * 1024 * 1024 } = {}) {
  const normalizedPrefix = prefix ? `${prefix.replace(/^\//, "").replace(/\/$/, "")}/` : "";
  
  const storage = multer.diskStorage({
    destination: (_req, _file, cb) => {
      // Crear el directorio específico si no existe
      const targetDir = path.join(UPLOADS_DIR, normalizedPrefix);
      if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
      }
      cb(null, targetDir);
    },
    filename: (req, file, cb) => {
      const timestamp = Date.now();
      const ext = path.extname(file.originalname) || "";
      const base = sanitizeFileName(path.basename(file.originalname, ext)) || "file";
      const rutCandidate = sanitizeFileName(
        String(
          (req && (req.body?.rutAlumno || req.body?.estudianteRut || req.body?.inscripcionId)) ||
            (req && req.params?.id) ||
            (req && req.user?.rut) ||
            ""
        )
      );
      const rutSuffix = rutCandidate ? `__rut-${rutCandidate}` : "";
      cb(null, `${timestamp}-${base}${rutSuffix}${ext}`);
    },
  });
  
  const uploaderInstance = multer({
    storage,
    limits: { fileSize },
  });
  
  // Wrapper para agregar campo 'location' después del upload
  return {
    single: (fieldName) => {
      return (req, res, next) => {
        uploaderInstance.single(fieldName)(req, res, (err) => {
          if (err) return next(err);
          
          // Si hay archivo, agregar campo 'location' para compatibilidad con controladores
          if (req.file) {
            // Construir ruta relativa desde uploads/
            const relativePath = path.relative(UPLOADS_DIR, req.file.path).replace(/\\/g, '/');
            req.file.location = `uploads/${relativePath}`;
            req.file.key = relativePath;
            
            console.log(`[multer] Archivo guardado: ${req.file.location}`);
          }
          
          next();
        });
      };
    },
    array: (fieldName, maxCount) => {
      return (req, res, next) => {
        uploaderInstance.array(fieldName, maxCount)(req, res, (err) => {
          if (err) return next(err);
          
          // Si hay archivos, agregar campo 'location' a cada uno
          if (req.files && Array.isArray(req.files)) {
            req.files.forEach(file => {
              const relativePath = path.relative(UPLOADS_DIR, file.path).replace(/\\/g, '/');
              file.location = `uploads/${relativePath}`;
              file.key = relativePath;
            });
            
            console.log(`[multer] ${req.files.length} archivos guardados`);
          }
          
          next();
        });
      };
    },
  };
}
