"use strict";
import multer from "multer";
import multerS3 from "multer-s3";
import path from "path";
import { s3Client } from "./s3.js";

function sanitizeFileName(name = "") {
  return name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, "_")
    .replace(/[^\w.\-]/g, "")
    .toLowerCase();
}

export function createS3Uploader(prefix = "", { fileSize = 5 * 1024 * 1024 } = {}) {
  const normalizedPrefix = prefix ? `${prefix.replace(/^\//, "").replace(/\/$/, "")}/` : "";
  
  const bucket = process.env.S3_BUCKET;
  if (!bucket) {
    console.warn("[multer-s3] S3_BUCKET no configurado, usando almacenamiento local como fallback");
    return multer({
      storage: multer.diskStorage({
        destination: (_req, _file, cb) => {
          cb(null, "uploads/");
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
          // Para disco local, incluir el prefix en el filename para consistencia
          cb(null, `${normalizedPrefix}${timestamp}-${base}${rutSuffix}${ext}`);
        },
      }),
      limits: {
        fileSize,
      },
    });
  }

  return multer({
    storage: multerS3({
      s3: s3Client,
      bucket,
      acl: "public-read",
      contentType: multerS3.AUTO_CONTENT_TYPE,
      key: (req, file, cb) => {
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
        cb(null, `${normalizedPrefix}${timestamp}-${base}${rutSuffix}${ext}`);
      },
    }),
    limits: {
      fileSize,
    },
  });
}
