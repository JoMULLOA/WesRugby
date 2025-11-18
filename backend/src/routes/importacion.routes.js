"use strict";
import { Router } from "express";
import { 
  importEstudiantesFromExcel,
  importFormulariosRegistro 
} from "../controllers/importacion.controller.js";

const router = Router();

// Endpoint temporal para importación masiva sin autenticación
router.post("/estudiantes-excel", importEstudiantesFromExcel);

// Endpoint para importar formularios de registro
router.post("/registro-formularios", importFormulariosRegistro);

export default router;