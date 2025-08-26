import { Router } from "express";
import {
  crearEventoDeportivo,
  obtenerEventosDeportivos,
  obtenerEventoPorId,
  actualizarEventoDeportivo,
  inscribirseEvento,
  confirmarParticipacion,
  obtenerCalendarioEventos,
  eliminarEventoDeportivo
} from "../controllers/eventoDeportivo.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isEntrenador,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear evento deportivo (Entrenador, Directiva)
router.post("/", authenticateJwt, isEntrenador, crearEventoDeportivo);

// Obtener eventos deportivos (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerEventosDeportivos);

// Obtener calendario de eventos (Todos los autenticados)
router.get("/calendario", authenticateJwt, isAuthenticated, obtenerCalendarioEventos);

// Obtener evento por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerEventoPorId);

// Actualizar evento deportivo (Entrenador, Directiva)
router.put("/:id", authenticateJwt, isEntrenador, actualizarEventoDeportivo);

// Inscribirse a evento (Todos los autenticados)
router.post("/:id/inscripcion", authenticateJwt, isAuthenticated, inscribirseEvento);

// Confirmar participación (Entrenador, Directiva)
router.patch("/:id/confirmar", authenticateJwt, isEntrenador, confirmarParticipacion);

// Eliminar evento (Solo Directiva)
router.delete("/:id", authenticateJwt, isDirectiva, eliminarEventoDeportivo);

export default router;
