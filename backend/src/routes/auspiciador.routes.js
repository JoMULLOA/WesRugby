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

const router = Router();

// Ruta pública - sin autenticación requerida
router.get("/publicos", getAuspiciadoresPublicos);

// Rutas para obtener auspiciadores (todos los roles autenticados)
router.get("/", authenticateJwt, getAuspiciadores);
router.get("/:id", authenticateJwt, getAuspiciador);

// CRUD de auspiciadores - solo directiva
router.post("/", authenticateJwt, isDirectiva, createAuspiciador);
router.put("/:id", authenticateJwt, isDirectiva, updateAuspiciador);
router.delete("/:id", authenticateJwt, isDirectiva, deleteAuspiciador);

// Gestión de estado - solo directiva
router.patch("/:id/estado", authenticateJwt, isDirectiva, changeEstadoAuspiciador);

export default router;