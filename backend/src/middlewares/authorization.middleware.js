import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
handleErrorClient,
handleErrorServer,
} from "../handlers/responseHandlers.js";

// Middleware para verificar rol de directiva (máximo nivel de acceso)
export async function isDirectiva(req, res, next) {
try {
    const userRepository = AppDataSource.getRepository(User);
    const userFound = await userRepository.findOneBy({ email: req.user.email });

    if (!userFound) {
        return handleErrorClient(
            res,
            404,
            "Usuario no encontrado en la base de datos",
        );
    }

    if (userFound.rol !== "directiva") {
        return handleErrorClient(
            res,
            403,
            "Error al acceder al recurso",
            "Se requiere rol de directiva para realizar esta acción."
        );
    }
    next();
} catch (error) {
    handleErrorServer(res, 500, error.message);
}
}

// Middleware para verificar rol de tesorera o directiva
export async function isTesorera(req, res, next) {
try {
    const userRepository = AppDataSource.getRepository(User);
    const userFound = await userRepository.findOneBy({ email: req.user.email });

    if (!userFound) {
        return handleErrorClient(
            res,
            404,
            "Usuario no encontrado en la base de datos",
        );
    }

    const allowedRoles = ["directiva", "tesorera"];
    if (!allowedRoles.includes(userFound.rol)) {
        return handleErrorClient(
            res,
            403,
            "Error al acceder al recurso",
            "Se requiere rol de tesorera o directiva para realizar esta acción."
        );
    }
    next();
} catch (error) {
    handleErrorServer(res, 500, error.message);
}
}

// Middleware para verificar rol de entrenador, tesorera o directiva
export async function isEntrenador(req, res, next) {
try {
    const userRepository = AppDataSource.getRepository(User);
    const userFound = await userRepository.findOneBy({ email: req.user.email });

    if (!userFound) {
        return handleErrorClient(
            res,
            404,
            "Usuario no encontrado en la base de datos",
        );
    }

    const allowedRoles = ["directiva", "tesorera", "entrenador"];
    if (!allowedRoles.includes(userFound.rol)) {
        return handleErrorClient(
            res,
            403,
            "Error al acceder al recurso",
            "Se requiere rol de entrenador, tesorera o directiva para realizar esta acción."
        );
    }
    next();
} catch (error) {
    handleErrorServer(res, 500, error.message);
}
}

// Middleware para verificar cualquier rol autenticado
export async function isAuthenticated(req, res, next) {
try {
    const userRepository = AppDataSource.getRepository(User);
    const userFound = await userRepository.findOneBy({ email: req.user.email });

    if (!userFound) {
        return handleErrorClient(
            res,
            404,
            "Usuario no encontrado en la base de datos",
        );
    }

    const validRoles = ["directiva", "tesorera", "apoderado", "entrenador"];
    if (!validRoles.includes(userFound.rol)) {
        return handleErrorClient(
            res,
            403,
            "Error al acceder al recurso",
            "Rol de usuario no válido."
        );
    }
    next();
} catch (error) {
    handleErrorServer(res, 500, error.message);
}
}

// Middleware legacy para compatibilidad (mapea a directiva)
export async function isAdmin(req, res, next) {
try {
    const userRepository = AppDataSource.getRepository(User);
    const userFound = await userRepository.findOneBy({ email: req.user.email });

    if (!userFound) {
    return handleErrorClient(
        res,
        404,
        "Usuario no encontrado en la base de datos",
    );
    }

    const rolUser = userFound.rol;

    // Mantiene compatibilidad con "administrador" y mapea a "directiva"
    if (rolUser !== "administrador" && rolUser !== "directiva") {
        return handleErrorClient(
            res,
            403,
            "Error al acceder al recurso",
            "Se requiere un rol de administrador o directiva para realizar esta acción."
        );
    }
    next();
} catch (error) {
    handleErrorServer(
    res,
    500,
    error.message,
    );
}
}