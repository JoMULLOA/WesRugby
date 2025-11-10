"use strict";
import { Router } from "express";
import { getClubInfo, updateClubInfo } from "../controllers/club.controller.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";

const router = Router();

// Obtener información del club (público)
router.get("/informacion", getClubInfo);

// Actualizar información del club (solo directiva)
router.post("/informacion", authenticateJwt, isDirectiva, updateClubInfo);

export default router;
