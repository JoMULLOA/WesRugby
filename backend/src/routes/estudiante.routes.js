"use strict";
import express from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isAdmin, isApoderado, isAuthenticated } from "../middlewares/authorization.middleware.js";
import {
  createEstudiante,
  getEstudiantes,
  getEstudiantesByApoderado,
  getMisEstudiantes,
  getEstudiante,
  updateEstudiante,
  deleteEstudiante,
  updateEstudianteFoto,
} from "../controllers/estudiante.controller.js";

const router = express.Router();

// Middleware para autenticar
router.use(authenticateJwt);

// Rutas para estudiantes
router.get("/", (req, res, next) => {
  // Permitir entrenadores, directiva y admin ver todos los estudiantes
  if (['entrenador', 'directiva', 'admin', 'tesorera'].includes(req.user.rol)) {
    next();
  } else {
    res.status(403).json({
      success: false,
      message: 'No tienes permisos para ver todos los estudiantes'
    });
  }
}, getEstudiantes); // GET /estudiantes - obtener todos los estudiantes
router.get("/mis-estudiantes", isApoderado, getMisEstudiantes); // GET /estudiantes/mis-estudiantes - obtener estudiantes del apoderado logueado
router.get("/por-apoderado", isApoderado, getEstudiantesByApoderado); // GET /estudiantes/por-apoderado?rut=xxx - obtener estudiantes por apoderado
router.get("/:rut", isAuthenticated, getEstudiante); // GET /estudiantes/:rut - obtener estudiante por RUT
router.post("/", isAdmin, createEstudiante); // POST /estudiantes - crear estudiante (solo admin)
router.put("/:rut", isApoderado, updateEstudiante); // PUT /estudiantes/:rut - actualizar estudiante (apoderado responsable, tesorera o directiva)
router.put("/:rut/foto", isApoderado, updateEstudianteFoto); // PUT /estudiantes/:rut/foto - actualizar foto de estudiante
router.delete("/:rut", isAdmin, deleteEstudiante); // DELETE /estudiantes/:rut - eliminar estudiante (solo admin)

export default router;