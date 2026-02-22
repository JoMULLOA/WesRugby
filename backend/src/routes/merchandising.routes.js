"use strict";
import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import {
  createMerchandising,
  getMerchandising,
  getMerchandisingPublico,
  getMerchandisingItem,
  updateMerchandising,
  deleteMerchandising,
  changeEstadoMerchandising,
} from "../controllers/merchandising.controller.js";

const router = Router();

// Ruta pública - sin autenticación requerida
router.get("/publico", getMerchandisingPublico);

// Rutas para obtener merchandising (todos los roles autenticados)
router.get("/", authenticateJwt, getMerchandising);
router.get("/:id", authenticateJwt, getMerchandisingItem);

// CRUD de merchandising - solo directiva
router.post("/", authenticateJwt, isDirectiva, createMerchandising);
router.put("/:id", authenticateJwt, isDirectiva, updateMerchandising);
router.delete("/:id", authenticateJwt, isDirectiva, deleteMerchandising);

// Gestión de estado - solo directiva
router.patch(
  "/:id/estado",
  authenticateJwt,
  isDirectiva,
  changeEstadoMerchandising,
);

export default router;
