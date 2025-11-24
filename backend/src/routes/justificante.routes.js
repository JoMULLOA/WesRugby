"use strict";
import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isApoderado, isDirectiva, isEntrenador } from "../middlewares/authorization.middleware.js";
import { uploadJustificacionAsistencia } from "../middlewares/upload.middleware.js";
import {
  crearJustificanteApoderado,
  listarJustificantesApoderado,
  listarJustificantesDirectiva,
  actualizarEstadoJustificante,
  actualizarMesesExencion,
  obtenerJustificadosPorFecha,
} from "../controllers/justificante.controller.js";

const router = Router();

// Apoderado crea justificante (prospectivo o retrospectivo)
router.post(
  "/apoderado",
  authenticateJwt,
  isApoderado,
  uploadJustificacionAsistencia.single("justificante"),
  crearJustificanteApoderado
);

// Apoderado lista sus justificantes
router.get(
  "/apoderado/mis",
  authenticateJwt,
  isApoderado,
  listarJustificantesApoderado
);

// Directiva lista todos
router.get(
  "/directiva",
  authenticateJwt,
  isDirectiva,
  listarJustificantesDirectiva
);

// Directiva actualiza estado
router.patch(
  "/:id/estado",
  authenticateJwt,
  isDirectiva,
  actualizarEstadoJustificante
);

// Actualizar meses de exención (solo directiva)
router.patch(
  "/:id/exenciones-meses",
  authenticateJwt,
  isDirectiva,
  actualizarMesesExencion
);

// Justificantes aprobados que cubren una fecha para múltiples estudiantes (entrenadores y directiva)
router.get(
  "/fecha/:fecha",
  authenticateJwt,
  (req, res, next) => {
    // Permitir acceso si es entrenador o directiva
    const userRole = req.user?.rol;
    if (['entrenador', 'directiva', 'admin'].includes(userRole)) {
      return next();
    }
    return res.status(403).json({ success: false, message: 'Acceso denegado' });
  },
  obtenerJustificadosPorFecha
);

export default router;
