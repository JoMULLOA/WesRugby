import { Router } from "express";
import {
  crearVentaProducto,
  obtenerVentas,
  obtenerVentaPorId,
  anularVenta,
  obtenerEstadisticasVentas,
  calcularTotalVenta,
  obtenerReporteVentas
} from "../controllers/ventaProducto.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isTesorera,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear venta de producto (Todos los autenticados)
router.post("/", authenticateJwt, isAuthenticated, crearVentaProducto);

// Obtener ventas (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerVentas);

// Calcular total de venta (Todos los autenticados)
router.post("/calcular-total", authenticateJwt, isAuthenticated, calcularTotalVenta);

// Obtener estadísticas (Directiva, Tesorera)
router.get("/estadisticas/resumen", authenticateJwt, isTesorera, obtenerEstadisticasVentas);

// Obtener reporte de ventas (Directiva, Tesorera)
router.get("/reporte", authenticateJwt, isTesorera, obtenerReporteVentas);

// Obtener venta por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerVentaPorId);

// Anular venta (Directiva, Tesorera)
router.patch("/:id/anular", authenticateJwt, isTesorera, anularVenta);

export default router;
