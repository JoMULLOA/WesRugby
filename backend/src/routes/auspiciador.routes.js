"use strict";
import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import {
  createAuspiciador,
  getAuspiciadores,
  getAuspiciadoresPublicos,
  getAuspiciador,
  updateAuspiciador,
  deleteAuspiciador,
  changeEstadoAuspiciador,
} from "../controllers/auspiciador.controller.js";
import { uploadAuspiciadorLogo } from "../middlewares/upload.middleware.js";

const router = Router();

// Ruta pública - sin autenticación requerida
router.get("/publicos", getAuspiciadoresPublicos);

// Rutas para obtener auspiciadores (todos los roles autenticados)
router.get("/", authenticateJwt, getAuspiciadores);
router.get("/:id", authenticateJwt, getAuspiciador);

// CRUD de auspiciadores - solo directiva
router.post(
  "/",
  authenticateJwt,
  isDirectiva,
  uploadAuspiciadorLogo.single("imagen"),
  createAuspiciador,
);
router.put(
  "/:id",
  authenticateJwt,
  isDirectiva,
  uploadAuspiciadorLogo.single("imagen"),
  updateAuspiciador,
);
router.delete("/:id", authenticateJwt, isDirectiva, deleteAuspiciador);

// Gestión de estado - solo directiva
router.patch("/:id/estado", authenticateJwt, isDirectiva, changeEstadoAuspiciador);

export default router;