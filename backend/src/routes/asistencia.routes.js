import { Router } from "express";
import {
  registrarAsistencia,
  obtenerAsistencias,
  actualizarAsistencia,
  registrarAsistenciaMasiva,
  obtenerEstadisticasAsistencia,
  eliminarAsistencia,
} from "../controllers/asistencia.controller.js";
import {
  subirJustificanteAsistencia,
  obtenerJustificacionesApoderado,
  obtenerAsistenciasPendientesJustificacion,
} from "../controllers/asistenciaJustificacion.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isEntrenador,
  isAuthenticated,
  isApoderado,
} from "../middlewares/authorization.middleware.js";
import { uploadJustificacionAsistencia } from "../middlewares/upload.middleware.js";

const router = Router();

// Registrar asistencia (Entrenador, Directiva)
router.post("/", authenticateJwt, isEntrenador, registrarAsistencia);

// Obtener asistencias (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerAsistencias);

// Actualizar asistencia (Entrenador, Directiva)
router.put("/:id", authenticateJwt, isEntrenador, actualizarAsistencia);

// Registro masivo de asistencia (Entrenador, Directiva)
router.post(
  "/masiva",
  authenticateJwt,
  isEntrenador,
  registrarAsistenciaMasiva,
);

// Obtener estadísticas de asistencia (Todos los autenticados)
router.get(
  "/estadisticas/resumen",
  authenticateJwt,
  isAuthenticated,
  obtenerEstadisticasAsistencia,
);

// Eliminar asistencia (Solo Directiva)
router.delete("/:id", authenticateJwt, isDirectiva, eliminarAsistencia);

// Subir justificante (Apoderado sobre su alumno)
router.post(
  "/:id/justificacion",
  authenticateJwt,
  isApoderado,
  uploadJustificacionAsistencia.single("justificante"),
  subirJustificanteAsistencia,
);

// Listar justificantes del apoderado
router.get(
  "/apoderado/justificaciones",
  authenticateJwt,
  isApoderado,
  obtenerJustificacionesApoderado,
);

// Obtener asistencias pendientes de justificación
router.get(
  "/apoderado/asistencias-pendientes",
  authenticateJwt,
  isApoderado,
  obtenerAsistenciasPendientesJustificacion,
);

export default router;
