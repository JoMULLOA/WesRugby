"use strict";
import { Router } from "express";
import { importEstudiantesFromExcel } from "../controllers/importacion.controller.js";

const router = Router();

// Endpoint temporal para importación masiva sin autenticación
router.post("/estudiantes-excel", importEstudiantesFromExcel);

export default router;