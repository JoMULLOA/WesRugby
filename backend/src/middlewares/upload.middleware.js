"use strict";
import { createS3Uploader } from "../config/multer-s3.js";

export const uploadEventoMultimedia = createS3Uploader("eventos", {
  fileSize: 6 * 1024 * 1024,
});

export const uploadAvatar = createS3Uploader("avatars", {
  fileSize: 4 * 1024 * 1024,
});

export const uploadAuspiciadorLogo = createS3Uploader("imagenes/auspiciadores", {
  fileSize: 5 * 1024 * 1024,
});

export const uploadVoucherComprobante = createS3Uploader("comprobantes", {
  fileSize: 10 * 1024 * 1024,
});

export const uploadEntrenadorFoto = createS3Uploader("imagenes/entrenadores", {
  fileSize: 5 * 1024 * 1024,
});

export const uploadPublicMedia = createS3Uploader("public", {
  fileSize: 8 * 1024 * 1024,
});
