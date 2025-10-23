import { Router } from "express";
import {
  crearEventoDeportivo,
  obtenerEventosDeportivos,
  obtenerEventoPorId,
  actualizarEventoDeportivo,
  inscribirseEvento,
  confirmarParticipacion,
  obtenerCalendarioEventos,
  eliminarEventoDeportivo,
} from "../controllers/eventoDeportivo.controller.js";
import {
  subirMultimediaDirectiva,
  subirMultimediaRama,
  obtenerMultimediaEventoDirectiva,
  obtenerMultimediaEventoCompartido,
  obtenerMultimediaGlobalDirectiva,
  descargarMultimediaEvento,
} from "../controllers/eventoMultimedia.controller.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isEntrenador,
  isAuthenticated,
  isRamaExterna,
} from "../middlewares/authorization.middleware.js";
import { uploadEventoMultimedia } from "../middlewares/upload.middleware.js";

const router = Router();

// Crear evento deportivo (Entrenador, Directiva)
router.post("/", authenticateJwt, isEntrenador, crearEventoDeportivo);

// Obtener eventos deportivos (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerEventosDeportivos);

// Resumen multimedia (Directiva)
router.get(
  "/multimedia/resumen",
  authenticateJwt,
  isDirectiva,
  obtenerMultimediaGlobalDirectiva,
);

// Obtener calendario de eventos (Todos los autenticados)
router.get(
  "/calendario",
  authenticateJwt,
  isAuthenticated,
  obtenerCalendarioEventos,
);

// Obtener evento por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerEventoPorId);

// Multimedia por evento (Directiva)
router.get(
  "/:id/multimedia",
  authenticateJwt,
  isDirectiva,
  obtenerMultimediaEventoDirectiva,
);

// Multimedia compartida (Directiva y ramas participantes)
router.get(
  "/:id/multimedia/compartido",
  authenticateJwt,
  isAuthenticated,
  obtenerMultimediaEventoCompartido,
);

router.get(
  "/:id/multimedia/:mediaId",
  authenticateJwt,
  isAuthenticated,
  descargarMultimediaEvento,
);

router.get(
  "/:id/multimedia/:mediaId/download",
  authenticateJwt,
  isAuthenticated,
  descargarMultimediaEvento,
);

// Actualizar evento deportivo (Entrenador, Directiva)
router.put("/:id", authenticateJwt, isEntrenador, actualizarEventoDeportivo);

// Inscribirse a evento (Todos los autenticados)
router.post(
  "/:id/inscripcion",
  authenticateJwt,
  isAuthenticated,
  inscribirseEvento,
);

// Confirmar participación (Entrenador, Directiva)
router.patch(
  "/:id/confirmar",
  authenticateJwt,
  isEntrenador,
  confirmarParticipacion,
);

// Eliminar evento (Solo Directiva)
router.delete("/:id", authenticateJwt, isDirectiva, eliminarEventoDeportivo);

// Subir multimedia (Directiva)
router.post(
  "/:id/multimedia",
  authenticateJwt,
  isDirectiva,
  uploadEventoMultimedia.single("archivo"),
  subirMultimediaDirectiva,
);

// Subir multimedia (Rama Externa participante)
router.post(
  "/:id/multimedia/rama",
  authenticateJwt,
  isRamaExterna,
  uploadEventoMultimedia.single("archivo"),
  subirMultimediaRama,
);

export default router;
