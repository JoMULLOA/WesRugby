"use strict";
import { Router } from "express";
import {
  createActaReunion,
  getActasReunion,
  getActaReunion,
  updateActaReunion,
  deleteActaReunion,
  changeEstadoActa,
} from "../controllers/actaReunion.controller.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva, isDirectivaOrTesorera, isDirectivaOrTesoreraOrApoderado } from "../middlewares/authorization.middleware.js";

const router = Router();

// Rutas protegidas por autenticación
router.use(authenticateJwt);

// Crear acta de reunión (solo directiva)
router.post("/", isDirectiva, createActaReunion);

// Obtener todas las actas (directiva, tesorera ven todas; apoderados solo publicadas)
router.get("/", isDirectivaOrTesoreraOrApoderado, getActasReunion);

// Obtener acta específica por ID (directiva, tesorera ven todas; apoderados solo publicadas)
router.get("/:id", isDirectivaOrTesoreraOrApoderado, getActaReunion);

// Actualizar acta de reunión (solo directiva)
router.put("/:id", isDirectiva, updateActaReunion);

// Eliminar acta de reunión (solo directiva)
router.delete("/:id", isDirectiva, deleteActaReunion);

// Cambiar estado del acta (solo directiva)
router.patch("/:id/estado", isDirectiva, changeEstadoActa);

export default router;