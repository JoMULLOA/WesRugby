import { Router } from "express";
import {
  crearProducto,
  obtenerProductos,
  obtenerProductoPorId,
  actualizarProducto,
  actualizarStock,
  obtenerProductosStockBajo,
  obtenerEstadisticasInventario,
  desactivarProducto,
  obtenerCategorias
} from "../controllers/producto.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isTesorera,
  isAuthenticated
} from "../middlewares/authorization.middleware.js";

const router = Router();

// Crear producto (Directiva, Tesorera)
router.post("/", authenticateJwt, isTesorera, crearProducto);

// Obtener productos (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerProductos);

// Obtener categorías disponibles (Todos los autenticados)
router.get("/categorias", authenticateJwt, isAuthenticated, obtenerCategorias);

// Obtener productos con stock bajo (Directiva, Tesorera)
router.get("/stock-bajo", authenticateJwt, isTesorera, obtenerProductosStockBajo);

// Obtener estadísticas de inventario (Directiva, Tesorera)
router.get("/estadisticas/inventario", authenticateJwt, isTesorera, obtenerEstadisticasInventario);

// Obtener producto por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerProductoPorId);

// Actualizar producto (Directiva, Tesorera)
router.put("/:id", authenticateJwt, isTesorera, actualizarProducto);

// Actualizar stock (Directiva, Tesorera)
router.patch("/:id/stock", authenticateJwt, isTesorera, actualizarStock);

// Desactivar producto (Solo Directiva)
router.patch("/:id/desactivar", authenticateJwt, isDirectiva, desactivarProducto);

export default router;
