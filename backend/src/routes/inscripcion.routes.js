import { Router } from "express";
import {
  crearInscripcion,
  obtenerInscripciones,
  obtenerInscripcionPorId,
  actualizarInscripcion,
  aprobarInscripcion,
  obtenerEstadisticasInscripciones,
  darDeBajaInscripcion
} from "../controllers/inscripcion.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isEntrenador,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear inscripción (Entrenador, Apoderado, Directiva)
router.post("/", authenticateJwt, isAuthenticated, crearInscripcion);

// Obtener inscripciones (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerInscripciones);

// Obtener inscripción por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerInscripcionPorId);

// Actualizar inscripción (Entrenador, Directiva)
router.put("/:id", authenticateJwt, isEntrenador, actualizarInscripcion);

// Aprobar inscripción (Solo Directiva)
router.patch("/:id/aprobar", authenticateJwt, isDirectiva, aprobarInscripcion);

// Obtener estadísticas (Entrenador, Directiva)
router.get("/estadisticas/resumen", authenticateJwt, isEntrenador, obtenerEstadisticasInscripciones);

// Dar de baja inscripción (Solo Directiva)
router.delete("/:id", authenticateJwt, isDirectiva, darDeBajaInscripcion);

export default router;
