import { Router } from "express";
import {
  crearMiembroDirectiva,
  obtenerMiembrosDirectiva,
  obtenerMiembroPorId,
  actualizarMiembroDirectiva,
  desactivarMiembroDirectiva,
  obtenerEstructuraOrganizacional,
  obtenerHistorialDirectiva,
  obtenerEstadisticasDirectiva,
  transferirCargo
} from "../controllers/directiva.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isTesorera,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear miembro de directiva (Solo Directiva)
router.post("/", authenticateJwt, isDirectiva, crearMiembroDirectiva);

// Obtener miembros de directiva (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerMiembrosDirectiva);

// Obtener estructura organizacional (Todos los autenticados)
router.get("/estructura", authenticateJwt, isAuthenticated, obtenerEstructuraOrganizacional);

// Obtener historial (Directiva, Tesorera)
router.get("/historial", authenticateJwt, isTesorera, obtenerHistorialDirectiva);

// Obtener estadísticas (Directiva, Tesorera)
router.get("/estadisticas/resumen", authenticateJwt, isTesorera, obtenerEstadisticasDirectiva);

// Obtener miembro por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerMiembroPorId);

// Actualizar miembro (Solo Directiva)
router.put("/:id", authenticateJwt, isDirectiva, actualizarMiembroDirectiva);

// Desactivar miembro (Solo Directiva)
router.patch("/:id/desactivar", authenticateJwt, isDirectiva, desactivarMiembroDirectiva);

// Transferir cargo (Solo Directiva)
router.post("/transferir-cargo", authenticateJwt, isDirectiva, transferirCargo);

export default router;
