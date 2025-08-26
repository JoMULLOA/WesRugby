import { Router } from "express";
import {
  crearComprobantePago,
  obtenerComprobantesPago,
  obtenerComprobantePorId,
  validarComprobante,
  actualizarComprobante,
  obtenerEstadisticasPagos,
  eliminarComprobante
} from "../controllers/comprobantePago.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isTesorera,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear comprobante de pago (Todos los autenticados)
router.post("/", authenticateJwt, isAuthenticated, crearComprobantePago);

// Obtener comprobantes (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerComprobantesPago);

// Obtener comprobante por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerComprobantePorId);

// Validar comprobante (Tesorera, Directiva)
router.patch("/:id/validar", authenticateJwt, isTesorera, validarComprobante);

// Actualizar comprobante (Todos los autenticados con restricciones)
router.put("/:id", authenticateJwt, isAuthenticated, actualizarComprobante);

// Obtener estadísticas (Tesorera, Directiva)
router.get("/estadisticas/resumen", authenticateJwt, isTesorera, obtenerEstadisticasPagos);

// Eliminar comprobante (Solo Directiva)
router.delete("/:id", authenticateJwt, isDirectiva, eliminarComprobante);

export default router;
