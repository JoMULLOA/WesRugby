"use strict";
import express from "express";
import { isAdmin, isDirectiva, isAuthenticated } from "../middlewares/authorization.middleware.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { deleteUser, getUser, getUsers, updateUser, searchUser, buscarRut, getMisVehiculos, calcularCalificacion, obtenerPromedioGlobal, actualizarTokenFCM, getHistorialTransacciones, calificarUsuario, changeUserRole, createUserByDirectiva, updateUserByDirectiva, deleteUserByDirectiva, updateAvatar } from "../controllers/user.controller.js";
import { AppDataSource } from "../config/configDb.js";
import User from "../entity/user.entity.js";
import { uploadAvatar as uploadAvatarMiddleware } from "../middlewares/upload.middleware.js";

const router = express.Router();

// Middleware para autenticar todas las rutas
router.use(authenticateJwt);

// Rutas que requieren solo autenticación
router.get("/busqueda", isAuthenticated, searchUser);
router.get("/busquedaRut", isAuthenticated, buscarRut);

//Ruta calificacion de usuario
router.post("/calcularCalificacion", calcularCalificacion);

// Nueva ruta para calificar usuarios con estrellas
router.post("/calificar", calificarUsuario);

// Nueva ruta para obtener el promedio global
router.get("/promedioGlobal", obtenerPromedioGlobal);

// Rutas de usuario - acceso general autenticado
router.get("/detail/", isAuthenticated, getUser);
router.get("/mis-vehiculos", isAuthenticated, getMisVehiculos); // Nueva ruta para obtener vehículos del usuario
router.get("/historial-transacciones", isAuthenticated, getHistorialTransacciones); // Nueva ruta para historial
router.patch("/actualizar", isAuthenticated, updateUser);
router.patch("/fcm-token", isAuthenticated, actualizarTokenFCM); // Nueva ruta para actualizar token FCM
router.post(
  "/avatar",
  isAuthenticated,
  uploadAvatarMiddleware.single("avatar"),
  updateAvatar,
);

// Rutas que requieren permisos de directiva
router.get("/", isDirectiva, getUsers); // GET /user/ - obtener todos los usuarios
router.get("/all", isDirectiva, getUsers); // GET /user/all - alias para obtener todos los usuarios (para el frontend)
router.post("/create", isDirectiva, createUserByDirectiva); // Nueva ruta para crear usuarios (solo directiva)
router.put("/update-by-directiva", isDirectiva, updateUserByDirectiva); // Nueva ruta para actualizar usuarios desde directiva
router.put("/changeRole", isDirectiva, changeUserRole); // Nueva ruta para cambiar rol de usuario (solo directiva)
router.delete("/detail/", isDirectiva, deleteUser); // Solo directiva puede eliminar usuarios
router.delete("/delete/:rut", isDirectiva, deleteUser); // Alias para eliminar por RUT (para el frontend)

// Endpoints específicos para directiva (con protección especial)
router.delete("/delete-by-directiva/:rut", isDirectiva, deleteUserByDirectiva); // Eliminar con protección de último directiva

export default router;
