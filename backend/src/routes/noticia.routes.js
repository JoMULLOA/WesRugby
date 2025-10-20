"use strict";
import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import {
  createNoticia,
  getNoticias,
  getNoticiasPublicas,
  getNoticia,
  updateNoticia,
  deleteNoticia,
  changeEstadoNoticia,
  toggleDestacada,
} from "../controllers/noticia.controller.js";

const router = Router();

// Ruta pública - sin autenticación requerida
router.get("/publicas", getNoticiasPublicas);

// Rutas para obtener noticias (todos los roles autenticados)
router.get("/", authenticateJwt, getNoticias);
router.get("/:id", authenticateJwt, getNoticia);

// CRUD de noticias - solo directiva
router.post("/", authenticateJwt, isDirectiva, createNoticia);
router.put("/:id", authenticateJwt, isDirectiva, updateNoticia);
router.delete("/:id", authenticateJwt, isDirectiva, deleteNoticia);

// Gestión de estado - solo directiva
router.patch("/:id/estado", authenticateJwt, isDirectiva, changeEstadoNoticia);
router.patch("/:id/destacada", authenticateJwt, isDirectiva, toggleDestacada);

export default router;