import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import {
  uploadImagen,
  getImagen,
  deleteImagen
} from "../controllers/upload.controller.js";

const router = Router();

// Subir imagen para información pública (Solo directiva)
router.post("/imagen", authenticateJwt, isDirectiva, uploadImagen);

// Obtener imagen por nombre
router.get("/imagen/:filename", getImagen);

// Eliminar imagen (Solo directiva)
router.delete("/imagen/:filename", authenticateJwt, isDirectiva, deleteImagen);

export default router;