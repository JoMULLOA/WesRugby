import jwt from "jsonwebtoken";
import { loginService, registerService } from "../services/auth.service.js";
import { authValidation, registerValidation } from "../validations/auth.validation.js";
import { handleErrorClient, handleErrorServer, handleSuccess } from "../handlers/responseHandlers.js";
import { ACCESS_TOKEN_SECRET } from "../config/configEnv.js";

export async function login(req, res) {
  try {
    const { error } = authValidation.validate(req.body);
    if (error) {
      return handleErrorClient(res, 400, "Error de validación", error.message);
    }

    const [accessToken, authError] = await loginService(req.body);
    if (authError) {
      return handleErrorClient(res, 400, "Error iniciando sesión", authError);
    }

    const decoded = jwt.verify(accessToken, ACCESS_TOKEN_SECRET);

    res.cookie("jwt", accessToken, {
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000,
      sameSite: "strict",
    });

    handleSuccess(res, 200, "Inicio de sesión exitoso", {
      token: accessToken,
      user: {
        id: decoded.id,
        fullName: decoded.fullName,
        nombreCompleto: decoded.nombreCompleto,
        email: decoded.email,
        rut: decoded.rut,
        role: decoded.role,
        rol: decoded.rol,
      },
    });
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function register(req, res) {
  try {
    const { error } = registerValidation.validate(req.body);
    if (error) {
      return handleErrorClient(res, 400, "Error de validación", error.message);
    }

    const [newUser, serviceError] = await registerService(req.body);
    if (serviceError) {
      return handleErrorClient(res, 400, "Error registrando al usuario", serviceError);
    }

    handleSuccess(res, 201, "Usuario registrado con éxito", newUser);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function logout(req, res) {
  try {
    res.clearCookie("jwt", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
    });

    handleSuccess(res, 200, "Sesión cerrada exitosamente", {
      message: "Logout completado",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    handleErrorServer(res, 500, "Error al cerrar sesión");
  }
}