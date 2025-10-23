"use strict";
import { loginService, registerService } from "../services/auth.service.js";
import {
  authValidation,
  registerValidation,
} from "../validations/auth.validation.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import jwt from "jsonwebtoken";
import { ACCESS_TOKEN_SECRET } from "../config/configEnv.js";

function buildAvatarUrl(req, avatarPath, avatarVersion) {
  if (!avatarPath) return null;
  const normalized = avatarPath.replace(/\\/g, "/");
  const baseUrl = `${req.protocol}://${req.get("host")}/uploads/${normalized}`;
  if (typeof avatarVersion === "number" && !Number.isNaN(avatarVersion)) {
    return `${baseUrl}?v=${avatarVersion}`;
  }
  return baseUrl;
}

export async function login(req, res) {
  try {
    const { body } = req;

    const { error } = authValidation.validate(body);

    if (error) {
      return handleErrorClient(res, 400, "Error de validación", error.message);
    }
    const [accessToken, errorToken] = await loginService(body);

    if (errorToken) return handleErrorClient(res, 400, "Error iniciando sesión", errorToken);

    // Decodificar el token para obtener la información del usuario
    const decoded = jwt.verify(accessToken, ACCESS_TOKEN_SECRET);

    res.cookie("jwt", accessToken, {
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000,
    });

    const avatarPath = decoded.avatarPath || null;
    const avatarVersion = Number.isFinite(decoded.avatarVersion)
      ? decoded.avatarVersion
      : 0;
    const avatarUrl = buildAvatarUrl(req, avatarPath, avatarVersion);

    // Devolver tanto el token como la información del usuario decodificada
    handleSuccess(res, 200, "Inicio de sesión exitoso", { 
      token: accessToken,
      user: {
        nombreCompleto: decoded.nombreCompleto,
        email: decoded.email,
        rut: decoded.rut,
        rol: decoded.rol,
        avatarPath,
        avatarUrl,
        avatarVersion,
      }
    });
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function register(req, res) {
  try {
    const { body } = req;
    const { error } = registerValidation.validate(body);
    console.log("error", error);
    if (error)
      return handleErrorClient(res, 400, "Error de validación", error.message);
    const [newUser, errorNewUser] = await registerService(body);
    console.log("newUser", errorNewUser);
    if (errorNewUser) return handleErrorClient(res, 400, "Error registrando al usuario", errorNewUser);

    handleSuccess(res, 201, "Usuario registrado con éxito", newUser);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function logout(req, res) {
  try {
    // Obtener información del usuario autenticado si está disponible
    const userInfo = req.user ? {
      email: req.user.email,
      rut: req.user.rut,
      nombreCompleto: req.user.nombreCompleto
    } : 'Usuario anónimo';

    // Log de seguridad para auditoría
    console.log(`🔐 LOGOUT: Usuario ${userInfo.email || 'anónimo'} cerró sesión en ${new Date().toISOString()}`);

    // Limpiar la cookie JWT
    res.clearCookie("jwt", { 
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production', // Solo HTTPS en producción
      sameSite: 'strict'
    });

    // En el futuro aquí se podría:
    // 1. Agregar el token a una blacklist
    // 2. Limpiar datos de sesión en Redis/caché
    // 3. Notificar a otros servicios

    handleSuccess(res, 200, "Sesión cerrada exitosamente", {
      message: "Logout completado",
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error("Error durante el logout:", error);
    handleErrorServer(res, 500, "Error al cerrar sesión");
  }
}

export async function getProfile(req, res) {
  try {
    // El usuario ya está autenticado por el middleware authenticateJwt
    const user = req.user;

    if (!user) {
      return handleErrorClient(res, 401, "No autenticado", "No se encontró información del usuario");
    }

    const avatarPath = user.avatarPath || null;
    const avatarVersion =
      typeof user.avatarVersion === "number" && !Number.isNaN(user.avatarVersion)
        ? user.avatarVersion
        : 0;
    const avatarUrl = buildAvatarUrl(req, avatarPath, avatarVersion);

    handleSuccess(res, 200, "Perfil obtenido exitosamente", {
      nombreCompleto: user.nombreCompleto,
      email: user.email,
      rut: user.rut,
      rol: user.rol,
      avatarPath,
      avatarUrl,
      avatarVersion,
    });
  } catch (error) {
    console.error("Error obteniendo perfil:", error);
    handleErrorServer(res, 500, "Error al obtener perfil del usuario");
  }
}
