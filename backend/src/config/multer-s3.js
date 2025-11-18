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
  return multer({
    storage: multerS3({
      s3: s3Client,
      bucket: process.env.S3_BUCKET,
      acl: "public-read",
      contentType: multerS3.AUTO_CONTENT_TYPE,
      key: (_req, file, cb) => {
        const timestamp = Date.now();
        const ext = path.extname(file.originalname) || "";
        const base = sanitizeFileName(path.basename(file.originalname, ext)) || "file";
        cb(null, `${normalizedPrefix}${timestamp}-${base}${ext}`);
      },
    }),
    limits: {
      fileSize,
    },
  });
}
