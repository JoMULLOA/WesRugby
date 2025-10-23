"use strict";
import multer from "multer";
import path from "path";
import fs from "fs";

const BASE_UPLOAD_DIR = path.resolve("uploads");

function ensureUploadDir(subDir) {
  const targetDir = path.resolve(BASE_UPLOAD_DIR, subDir);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }
  return targetDir;
}

function sanitizeFileName(originalName) {
  return originalName
    .replace(/\s+/g, "_")
    .replace(/[^\w.\-]/g, "")
    .toLowerCase();
}

function createUploader(subDir, { fileSize }) {
  const storage = multer.diskStorage({
    destination: function (req, file, cb) {
      try {
        const dir = ensureUploadDir(subDir);
        cb(null, dir);
      } catch (error) {
        cb(error);
      }
    },
    filename: function (req, file, cb) {
      const timestamp = Date.now();
      const safeName = sanitizeFileName(file.originalname);
      cb(null, `${timestamp}-${safeName}`);
    },
  });

  function fileFilter(req, file, cb) {
    const allowed = ["image/jpeg", "image/png", "image/webp", "image/gif"];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Tipo de archivo no permitido. Use JPG, PNG, WEBP o GIF."));
    }
  }

  return multer({
    storage,
    fileFilter,
    limits: {
      fileSize,
    },
  });
}

export const uploadEventoMultimedia = createUploader("eventos", {
  fileSize: 6 * 1024 * 1024,
});

export const uploadAvatar = createUploader("avatars", {
  fileSize: 4 * 1024 * 1024,
});

export const uploadAuspiciadorLogo = createUploader(path.join("imagenes", "auspiciadores"), {
  fileSize: 5 * 1024 * 1024,
});
