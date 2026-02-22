import { Router } from "express";
import {
  createSesionAsistencia,
  getMisSesiones,
  getSesionDetalle,
  getEstadisticasAsistencia,
  getCategorias,
  getAllSesiones,
} from "../controllers/sesionAsistencia.controller.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isEntrenador } from "../middlewares/authorization.middleware.js";

const router = Router();

// Obtener categorías disponibles
router.get("/categorias", authenticateJwt, getCategorias);

// Crear nueva sesión de asistencia (solo entrenadores)
router.post("/", authenticateJwt, isEntrenador, createSesionAsistencia);

// Obtener TODAS las sesiones (para directiva, entrenador y apoderado)
router.get(
  "/todas",
  authenticateJwt,
  (req, res, next) => {
    // Permitir entrenadores, directiva y apoderados
    if (
      req.user.rol === "entrenador" ||
      req.user.rol === "directiva" ||
      req.user.rol === "apoderado"
    ) {
      next();
    } else {
      res.status(403).json({
        success: false,
        message: "No tienes permisos para acceder a este recurso",
      });
    }
  },
  getAllSesiones,
);

// Obtener sesiones del entrenador autenticado
router.get("/mis-sesiones", authenticateJwt, isEntrenador, getMisSesiones);

// Obtener detalles de una sesión específica
router.get("/:sesionId", authenticateJwt, isEntrenador, getSesionDetalle);

// Obtener estadísticas de asistencia (entrenadores y directiva)
router.get(
  "/estadisticas/general",
  authenticateJwt,
  (req, res, next) => {
    // Permitir tanto entrenadores como directiva
    if (req.user.rol === "entrenador" || req.user.rol === "directiva") {
      next();
    } else {
      res.status(403).json({
        success: false,
        message: "No tienes permisos para acceder a las estadísticas",
      });
    }
  },
  getEstadisticasAsistencia,
);

export default router;
