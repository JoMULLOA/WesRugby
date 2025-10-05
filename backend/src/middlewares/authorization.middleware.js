import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import { handleErrorClient, handleErrorServer } from "../handlers/responseHandlers.js";

async function findUserByEmail(email) {
  const userRepository = AppDataSource.getRepository(User);
  return userRepository.findOne({ where: { email } });
}

function ensureRole(user) {
  if (!user) {
    return null;
  }

  if (!user.role && user.rol) {
    user.role = user.rol;
  }

  if (!user.rol && user.role) {
    user.rol = user.role;
  }

  return user;
}

async function authorize(req, res, next, allowedRoles) {
  try {
    const user = ensureRole(await findUserByEmail(req.user?.email));
    if (!user) {
      return handleErrorClient(res, 404, "Usuario no encontrado en la base de datos");
    }

    if (!allowedRoles.includes(user.role)) {
      return handleErrorClient(
        res,
        403,
        "Error al acceder al recurso",
        "No cuenta con permisos suficientes para realizar esta acción."
      );
    }

    req.user.role = user.role;
    req.user.rol = user.role; // compatibilidad temporal
    next();
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export function isDirectiva(req, res, next) {
  return authorize(req, res, next, ["directiva"]);
}

export function isTesorera(req, res, next) {
  return authorize(req, res, next, ["directiva", "tesorera"]);
}

export function isEntrenador(req, res, next) {
  return authorize(req, res, next, ["directiva", "tesorera", "entrenador"]);
}

export function isAuthenticated(req, res, next) {
  return authorize(req, res, next, ["directiva", "tesorera", "apoderado", "entrenador", "administrador"]);
}

export function isAdmin(req, res, next) {
  return authorize(req, res, next, ["administrador", "directiva"]);
}