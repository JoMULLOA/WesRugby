"use strict";
import { Router } from "express";
import passport from "passport";
import { 
  crearEvento,
  obtenerEventos,
  obtenerEventosDisponibles,
  participarEnEvento,
  editarParticipacion,
  obtenerMisParticipacionesEvento,
  obtenerCategoriasRegistradas,
  actualizarEvento,
  eliminarEvento,
  obtenerParticipacionesEvento
} from "../controllers/evento.controller.js";
import { isDirectiva, isRamaExterna, isAuthenticated } from "../middlewares/authorization.middleware.js";

const router = Router();

// Middleware de autenticación para todas las rutas
const authenticateJWT = passport.authenticate("jwt", { session: false });

// Rutas para directiva
router
  .post("/crear", authenticateJWT, isDirectiva, crearEvento)
  .get("/todos", authenticateJWT, isDirectiva, obtenerEventos)
  .put("/:id", authenticateJWT, isDirectiva, actualizarEvento)
  .delete("/:id", authenticateJWT, isDirectiva, eliminarEvento)
  .get("/:id/participaciones", authenticateJWT, isDirectiva, obtenerParticipacionesEvento);

// Rutas para RamaExterna
router
  .get("/disponibles", authenticateJWT, isRamaExterna, obtenerEventosDisponibles)
  .post("/participar", authenticateJWT, isRamaExterna, participarEnEvento)
  .put("/participacion/:participacionId", authenticateJWT, isRamaExterna, editarParticipacion)
  .get("/:eventoId/categorias-registradas", authenticateJWT, isRamaExterna, obtenerCategoriasRegistradas);

// Rutas compartidas entre Directiva y RamaExterna
router
  .get("/mis-participaciones", authenticateJWT, isAuthenticated, obtenerMisParticipacionesEvento);

// Rutas generales (todos los roles autenticados)
router
  .get("/publicos", authenticateJWT, isAuthenticated, obtenerEventosDisponibles);

export default router;