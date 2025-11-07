"use strict";
import { Router } from "express";
import {
  obtenerPreciosPorAnio,
  guardarPrecios,
  obtenerTodasLasConfiguraciones,
} from "../controllers/configuracionPrecio.controller.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isTesorera } from "../middlewares/authorization.middleware.js";

const router = Router();

// Rutas públicas autenticadas (cualquier usuario puede ver precios)
router.get("/anio/:anio", authenticateJwt, obtenerPreciosPorAnio);

// Rutas solo para tesorera
router.post("/", authenticateJwt, isTesorera, guardarPrecios);
router.get("/", authenticateJwt, isTesorera, obtenerTodasLasConfiguraciones);

export default router;
