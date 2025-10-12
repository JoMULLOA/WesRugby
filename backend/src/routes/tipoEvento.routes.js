import { Router } from "express";
import {
  obtenerTiposEvento,
  obtenerTodosTiposEvento,
  crearTipoEvento,
  actualizarTipoEvento,
  eliminarTipoEvento,
  reactivarTipoEvento
} from "../controllers/tipoEvento.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva, isAuthenticated } from "../middlewares/authorization.middleware.js";

const router = Router();

// Rutas públicas (requieren autenticación pero cualquier rol puede acceder)
router.get("/", authenticateJwt, isAuthenticated, obtenerTiposEvento);

// Rutas solo para directiva
router.get("/todos", authenticateJwt, isDirectiva, obtenerTodosTiposEvento);
router.post("/", authenticateJwt, isDirectiva, crearTipoEvento);
router.put("/:id", authenticateJwt, isDirectiva, actualizarTipoEvento);
router.delete("/:id", authenticateJwt, isDirectiva, eliminarTipoEvento);
router.patch("/:id/reactivar", authenticateJwt, isDirectiva, reactivarTipoEvento);

export default router;