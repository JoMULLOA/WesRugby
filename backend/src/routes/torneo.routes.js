"use strict";
import { Router } from "express";
import {
  crearTorneo,
  obtenerTorneos,
  obtenerTorneosDisponibles,
  participarEnTorneo,
  obtenerMisParticipaciones,
  actualizarEstadoTorneo,
} from "../controllers/torneo.controller.js";
import {
  isDirectiva,
  isRamaExterna,
  isAuthenticated,
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Rutas para directiva
router
  .post("/crear", isDirectiva, crearTorneo)
  .get("/todos", isDirectiva, obtenerTorneos)
  .put("/:id/estado", isDirectiva, actualizarEstadoTorneo);

// Rutas para RamaExterna
router
  .get("/disponibles", isRamaExterna, obtenerTorneosDisponibles)
  .post("/participar", isRamaExterna, participarEnTorneo)
  .get("/mis-participaciones", isRamaExterna, obtenerMisParticipaciones);

// Rutas generales (todos los roles autenticados)
router.get("/publicos", isAuthenticated, obtenerTorneosDisponibles);

export default router;
