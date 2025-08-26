import { Router } from "express";
import {
  crearPlanPago,
  obtenerPlanesPago,
  obtenerPlanPagoPorId,
  actualizarPlanPago,
  desactivarPlanPago,
  obtenerEstadisticasPlanes,
  calcularMontoConDescuentos
} from "../controllers/planPago.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isTesorera,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear plan de pago (Directiva, Tesorera)
router.post("/", authenticateJwt, isTesorera, crearPlanPago);

// Obtener planes de pago (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerPlanesPago);

// Obtener plan por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerPlanPagoPorId);

// Actualizar plan de pago (Directiva, Tesorera)
router.put("/:id", authenticateJwt, isTesorera, actualizarPlanPago);

// Desactivar plan de pago (Solo Directiva)
router.patch("/:id/desactivar", authenticateJwt, isDirectiva, desactivarPlanPago);

// Obtener estadísticas (Directiva, Tesorera)
router.get("/estadisticas/resumen", authenticateJwt, isTesorera, obtenerEstadisticasPlanes);

// Calcular monto con descuentos (Todos los autenticados)
router.post("/calcular-monto", authenticateJwt, isAuthenticated, calcularMontoConDescuentos);

export default router;
