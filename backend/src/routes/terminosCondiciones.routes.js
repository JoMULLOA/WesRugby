import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  obtenerTerminosActivos,
  verificarAceptacion,
  aceptarTerminos,
  listarTerminos,
  crearTerminos,
  actualizarTerminos,
  eliminarTerminos,
  obtenerEstadisticasAceptacion,
} from "../controllers/terminosCondiciones.controller.js";

const router = Router();

// Rutas públicas (para apoderados que inician sesión)
router.get("/activo", obtenerTerminosActivos);

// Rutas protegidas para apoderados
router.get("/verificar-aceptacion", authenticateJwt, verificarAceptacion);
router.post("/aceptar", authenticateJwt, aceptarTerminos);

// Rutas protegidas para directiva
router.get("/", authenticateJwt, listarTerminos);
router.post("/", authenticateJwt, crearTerminos);
router.put("/:id", authenticateJwt, actualizarTerminos);
router.delete("/:id", authenticateJwt, eliminarTerminos);
router.get("/:id/estadisticas", authenticateJwt, obtenerEstadisticasAceptacion);

export default router;
