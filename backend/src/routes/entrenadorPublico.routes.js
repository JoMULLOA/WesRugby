"use strict";
import express from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import {
  getEntrenadoresPublicos,
  getEntrenadorPublico,
  crearEntrenadorPublico,
  actualizarEntrenadorPublico,
  eliminarEntrenadorPublico,
  toggleVisibilidadEntrenador,
  getEntrenadoresParaGestion,
} from "../controllers/entrenadorPublico.controller.js";

const router = express.Router();

// Rutas públicas (sin autenticación)
router.get("/publicos", getEntrenadoresPublicos);
router.get("/publicos/:id", getEntrenadorPublico);

// Rutas protegidas (solo directiva)
router.use(authenticateJwt);
router.use(isDirectiva);

router.get("/gestion", getEntrenadoresParaGestion);
router.post("/", crearEntrenadorPublico);
router.put("/:id", actualizarEntrenadorPublico);
router.delete("/:id", eliminarEntrenadorPublico);
router.patch("/:id/visibilidad", toggleVisibilidadEntrenador);

export default router;
