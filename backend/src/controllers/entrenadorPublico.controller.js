"use strict";
import fs from "fs";
import path from "path";
import { AppDataSource } from "../config/configDb.js";
import EntrenadorPublico from "../entity/entrenadorPublico.entity.js";
import User from "../entity/user.entity.js";
import { handleErrorClient, handleErrorServer, handleSuccess } from "../handlers/responseHandlers.js";
import { optimizeUploadedImage } from "../utils/image.utils.js";

const entrenadorPublicoRepository = AppDataSource.getRepository(EntrenadorPublico);
const userRepository = AppDataSource.getRepository(User);
const UPLOADS_BASE_PATH = path.resolve("uploads");

function deleteIfExists(filePath) {
  try {
    if (filePath && fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  } catch (error) {
    console.warn("No se pudo eliminar el archivo:", error.message);
  }
}

function buildAvatarUrl(req, relativePath, version) {
  if (!relativePath) {
    return null;
  }

  const normalized = relativePath.replace(/\\/g, "/");
  const prefixed = normalized.startsWith("uploads/")
    ? normalized
    : `uploads/${normalized}`;

  const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get("host")}`;
  if (typeof version === "number" && !Number.isNaN(version)) {
    return `${baseUrl}/${prefixed}?v=${version}`;
  }

  return `${baseUrl}/${prefixed}`;
}

function buildPublicFileUrl(relativePath, version, req) {
  if (!relativePath) {
    return null;
  }

  const normalized = relativePath.replace(/\\/g, "/");
  const prefixed = normalized.startsWith("uploads/")
    ? normalized
    : `uploads/${normalized}`;

  let baseUrl = process.env.BASE_URL;
  if (!baseUrl && req) {
    baseUrl = `${req.protocol}://${req.get("host")}`;
  }

  if (!baseUrl) {
    return version ? `/${prefixed}?v=${version}` : `/${prefixed}`;
  }

  return version ? `${baseUrl}/${prefixed}?v=${version}` : `${baseUrl}/${prefixed}`;
}

function ensureRelativeUploadPath(filePath) {
  return path.relative(UPLOADS_BASE_PATH, filePath).replace(/\\/g, "/");
}

function validateTextField(value, field, { required = false, minLength = 0, maxLength = 255 } = {}, errors) {
  const provided = value !== undefined;
  if (!provided) {
    if (required) {
      errors.push({ field, message: `El campo ${field} es obligatorio.` });
    }
    return { provided: false, value: undefined };
  }

  if (value === null) {
    if (required) {
      errors.push({ field, message: `El campo ${field} es obligatorio.` });
    }
    return { provided: true, value: null };
  }

  if (typeof value !== "string") {
    errors.push({ field, message: `El campo ${field} debe ser texto.` });
    return { provided: true, value: null };
  }

  const trimmed = value.trim();

  if (trimmed.length === 0) {
    if (required) {
      errors.push({ field, message: `El campo ${field} es obligatorio.` });
      return { provided: true, value: null };
    }
    return { provided: true, value: null };
  }

  if (minLength > 0 && trimmed.length < minLength) {
    errors.push({
      field,
      message: `El campo ${field} debe tener al menos ${minLength} caracteres.`,
    });
  }

  if (maxLength > 0 && trimmed.length > maxLength) {
    errors.push({
      field,
      message: `El campo ${field} no puede superar los ${maxLength} caracteres.`,
    });
  }

  return { provided: true, value: trimmed };
}

function validateExperience(value, { required = false } = {}, errors) {
  const provided = value !== undefined && value !== null && value !== "";
  if (!provided) {
    if (required) {
      errors.push({
        field: "aniosExperiencia",
        message: "Los años de experiencia son obligatorios.",
      });
    }
    return { provided: false, value: undefined };
  }

  const parsed = Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) {
    errors.push({
      field: "aniosExperiencia",
      message: "Los años de experiencia deben ser un número entero válido.",
    });
    return { provided: true, value: null };
  }

  if (parsed <= 0) {
    errors.push({
      field: "aniosExperiencia",
      message: "Los años de experiencia deben ser mayores a 0.",
    });
  } else if (parsed >= 100) {
    errors.push({
      field: "aniosExperiencia",
      message: "Los años de experiencia deben ser menores a 100.",
    });
  }

  return { provided: true, value: parsed };
}

function validateBooleanField(value, field, errors) {
  if (value === undefined || value === null) {
    return { provided: false, value: undefined };
  }

  if (typeof value === "boolean") {
    return { provided: true, value };
  }

  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (["true", "1", "si", "sí"].includes(normalized)) {
      return { provided: true, value: true };
    }
    if (["false", "0", "no"].includes(normalized)) {
      return { provided: true, value: false };
    }
  }

  errors.push({
    field,
    message: `El campo ${field} debe ser booleano.`,
  });
  return { provided: false, value: undefined };
}

function validateIntegerField(value, field, { min = 0, max = 999 } = {}, errors) {
  const provided = value !== undefined && value !== null && value !== "";
  if (!provided) {
    return { provided: false, value: undefined };
  }

  const parsed = Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) {
    errors.push({
      field,
      message: `El campo ${field} debe ser un número entero válido.`,
    });
    return { provided: true, value: null };
  }

  if (parsed < min || parsed > max) {
    errors.push({
      field,
      message: `El campo ${field} debe estar entre ${min} y ${max}.`,
    });
  }

  return { provided: true, value: parsed };
}

function sanitizeEntrenadorPayload(payload, { requireCoreFields = false } = {}) {
  const errors = [];
  const sanitized = {};

  const titulo = validateTextField(payload.titulo, "titulo", { required: requireCoreFields, minLength: 3, maxLength: 255 }, errors);
  if (titulo.provided) sanitized.titulo = titulo.value ?? null;

  const especialidad = validateTextField(payload.especialidad, "especialidad", { required: requireCoreFields, minLength: 3, maxLength: 255 }, errors);
  if (especialidad.provided) sanitized.especialidad = especialidad.value ?? null;

  const categorias = validateTextField(payload.categorias, "categorias", { required: requireCoreFields, minLength: 2, maxLength: 500 }, errors);
  if (categorias.provided) sanitized.categorias = categorias.value ?? null;

  const biografia = validateTextField(payload.biografia, "biografia", { required: requireCoreFields, minLength: 20, maxLength: 2000 }, errors);
  if (biografia.provided) sanitized.biografia = biografia.value ?? null;

  const logros = validateTextField(payload.logros, "logros", { required: false, minLength: 0, maxLength: 1500 }, errors);
  if (logros.provided) sanitized.logros = logros.value ?? null;

  const certificaciones = validateTextField(payload.certificaciones, "certificaciones", { required: false, minLength: 0, maxLength: 1500 }, errors);
  if (certificaciones.provided) sanitized.certificaciones = certificaciones.value ?? null;

  const experiencia = validateExperience(payload.aniosExperiencia, { required: requireCoreFields }, errors);
  if (experiencia.provided) sanitized.aniosExperiencia = experiencia.value ?? null;

  const visible = validateBooleanField(payload.visible, "visible", errors);
  if (visible.provided) sanitized.visible = visible.value;

  const ordenVisualizacion = validateIntegerField(payload.ordenVisualizacion, "ordenVisualizacion", { min: 0, max: 999 }, errors);
  if (ordenVisualizacion.provided) sanitized.ordenVisualizacion = ordenVisualizacion.value ?? 0;

  return { sanitized, errors };
}

/**
 * @name getEntrenadoresPublicos
 * @description Obtiene todos los entrenadores con información pública visible (endpoint público)
 */
export async function getEntrenadoresPublicos(req, res) {
  try {
    const entrenadores = await entrenadorPublicoRepository.find({
      where: { visible: true },
      relations: ["user"],
      order: { ordenVisualizacion: "ASC", createdAt: "DESC" },
    });

    // Formatear respuesta con información del usuario
    const entrenadoresFormateados = entrenadores.map((entrenador) => {
      const fotoUrl = buildPublicFileUrl(
        entrenador.fotoPath,
        entrenador.fotoVersion,
        req,
      );
      const avatarUrl = buildPublicFileUrl(
        entrenador.user?.avatarPath,
        entrenador.user?.avatarVersion,
        req,
      );

      return {
        id: entrenador.id,
        nombreCompleto: entrenador.user?.nombreCompleto || "Sin nombre",
        email: entrenador.user?.email,
        avatar: avatarUrl,
        foto: fotoUrl,
        titulo: entrenador.titulo,
        especialidad: entrenador.especialidad,
        aniosExperiencia: entrenador.aniosExperiencia,
        certificaciones: entrenador.certificaciones,
        logros: entrenador.logros,
        biografia: entrenador.biografia,
        categorias: entrenador.categorias,
        ordenVisualizacion: entrenador.ordenVisualizacion,
      };
    });

    handleSuccess(res, 200, "Entrenadores públicos obtenidos", entrenadoresFormateados);
  } catch (error) {
    console.error("Error al obtener entrenadores públicos:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name getEntrenadorPublico
 * @description Obtiene información pública de un entrenador específico
 */
export async function getEntrenadorPublico(req, res) {
  try {
    const { id } = req.params;

    const entrenador = await entrenadorPublicoRepository.findOne({
      where: { id: parseInt(id) },
      relations: ["user"],
    });

    if (!entrenador) {
      return handleErrorClient(res, 404, "Entrenador no encontrado");
    }

    const entrenadorFormateado = {
      id: entrenador.id,
      nombreCompleto: entrenador.user?.nombreCompleto || "Sin nombre",
      email: entrenador.user?.email,
      avatar: buildPublicFileUrl(
        entrenador.user?.avatarPath,
        entrenador.user?.avatarVersion,
        req,
      ),
      foto: buildPublicFileUrl(
        entrenador.fotoPath,
        entrenador.fotoVersion,
        req,
      ),
      titulo: entrenador.titulo,
      especialidad: entrenador.especialidad,
      aniosExperiencia: entrenador.aniosExperiencia,
      certificaciones: entrenador.certificaciones,
      logros: entrenador.logros,
      biografia: entrenador.biografia,
      categorias: entrenador.categorias,
      visible: entrenador.visible,
      ordenVisualizacion: entrenador.ordenVisualizacion,
    };

    handleSuccess(res, 200, "Entrenador público obtenido", entrenadorFormateado);
  } catch (error) {
    console.error("Error al obtener entrenador público:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name crearEntrenadorPublico
 * @description Crea o actualiza información pública de un entrenador (solo directiva)
 */
export async function crearEntrenadorPublico(req, res) {
  try {
    const { userRut } = req.body;
    if (!userRut || typeof userRut !== "string" || userRut.trim().length < 5) {
      return handleErrorClient(res, 400, "El RUT del usuario es requerido");
    }

    const { sanitized, errors } = sanitizeEntrenadorPayload(req.body, {
      requireCoreFields: true,
    });

    if (errors.length > 0) {
      return handleErrorClient(res, 400, "Datos de entrenador inválidos", {
        errores: errors,
      });
    }

    const usuario = await userRepository.findOne({ where: { rut: userRut } });
    if (!usuario) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    if (usuario.rol !== "entrenador") {
      return handleErrorClient(res, 400, "El usuario debe tener rol de entrenador");
    }

    let entrenador = await entrenadorPublicoRepository.findOne({
      where: { userRut },
    });

    sanitized.visible = sanitized.visible ?? true;
    sanitized.ordenVisualizacion = sanitized.ordenVisualizacion ?? 0;

    if (entrenador) {
      Object.assign(entrenador, sanitized);
      await entrenadorPublicoRepository.save(entrenador);
      handleSuccess(res, 200, "Perfil publico de entrenador actualizado", entrenador);
    } else {
      const nuevoEntrenador = entrenadorPublicoRepository.create({
        userRut,
        ...sanitized,
      });

      await entrenadorPublicoRepository.save(nuevoEntrenador);
      handleSuccess(res, 201, "Perfil publico de entrenador creado", nuevoEntrenador);
    }
  } catch (error) {
    console.error("Error al crear/actualizar entrenador publico:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name actualizarEntrenadorPublico
 * @description Actualiza información pública de un entrenador (solo directiva)
 */
export async function actualizarEntrenadorPublico(req, res) {
  try {
    const { id } = req.params;
    const entrenador = await entrenadorPublicoRepository.findOne({
      where: { id: parseInt(id) },
    });

    if (!entrenador) {
      return handleErrorClient(res, 404, "Entrenador no encontrado");
    }

    const { sanitized, errors } = sanitizeEntrenadorPayload(req.body, {
      requireCoreFields: false,
    });

    if (errors.length > 0) {
      return handleErrorClient(res, 400, "Datos de entrenador inválidos", {
        errores: errors,
      });
    }

    const keys = Object.keys(sanitized).filter(
      (key) => sanitized[key] !== undefined && key !== "userRut",
    );

    if (keys.length === 0) {
      return handleErrorClient(res, 400, "No hay datos para actualizar");
    }

    keys.forEach((key) => {
      entrenador[key] = sanitized[key];
    });

    await entrenadorPublicoRepository.save(entrenador);
    handleSuccess(res, 200, "Entrenador publico actualizado", entrenador);
  } catch (error) {
    console.error("Error al actualizar entrenador publico:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name eliminarEntrenadorPublico
 * @description Elimina información pública de un entrenador (solo directiva)
 */
export async function eliminarEntrenadorPublico(req, res) {
  try {
    const { id } = req.params;

    const entrenador = await entrenadorPublicoRepository.findOne({
      where: { id: parseInt(id) },
    });

    if (!entrenador) {
      return handleErrorClient(res, 404, "Entrenador no encontrado");
    }

    if (entrenador.fotoPath) {
      const previousPath = path.resolve(UPLOADS_BASE_PATH, entrenador.fotoPath);
      deleteIfExists(previousPath);
    }

    await entrenadorPublicoRepository.remove(entrenador);
    handleSuccess(res, 200, "Perfil público de entrenador eliminado");
  } catch (error) {
    console.error("Error al eliminar entrenador público:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name toggleVisibilidadEntrenador
 * @description Cambia la visibilidad de un entrenador (solo directiva)
 */
export async function toggleVisibilidadEntrenador(req, res) {
  try {
    const { id } = req.params;
    const { visible } = req.body;

    const entrenador = await entrenadorPublicoRepository.findOne({
      where: { id: parseInt(id) },
    });

    if (!entrenador) {
      return handleErrorClient(res, 404, "Entrenador no encontrado");
    }

    entrenador.visible = visible !== undefined ? visible : !entrenador.visible;
    await entrenadorPublicoRepository.save(entrenador);

    handleSuccess(
      res,
      200,
      `Entrenador ${entrenador.visible ? "visible" : "oculto"}`,
      entrenador
    );
  } catch (error) {
    console.error("Error al cambiar visibilidad:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name getEntrenadoresParaGestion
 * @description Obtiene todos los entrenadores del sistema para gestión (solo directiva)
 */
export async function getEntrenadoresParaGestion(req, res) {
  try {
    // Obtener todos los usuarios con rol entrenador
    const entrenadores = await userRepository.find({
      where: { rol: "entrenador" },
      select: ["rut", "nombreCompleto", "email", "avatarPath", "avatarVersion"],
      order: { nombreCompleto: "ASC" },
    });

    // Obtener perfiles públicos existentes
    const perfilesPublicos = await entrenadorPublicoRepository.find();
    const perfilesMap = new Map(perfilesPublicos.map((p) => [p.userRut, p]));

    // Combinar información
    const entrenadoresConPerfil = entrenadores.map((entrenador) => {
      const perfilPublico = perfilesMap.get(entrenador.rut);
      const fotoUrl = buildPublicFileUrl(
        perfilPublico?.fotoPath,
        perfilPublico?.fotoVersion,
        req,
      );
      const avatarUrl = buildPublicFileUrl(
        entrenador.avatarPath,
        entrenador.avatarVersion,
        req,
      );
      return {
        rut: entrenador.rut,
        nombreCompleto: entrenador.nombreCompleto,
        email: entrenador.email,
        avatar: avatarUrl,
        foto: fotoUrl,
        tienePerfil: !!perfilPublico,
        perfilPublico: perfilPublico
          ? {
              ...perfilPublico,
              fotoUrl,
            }
          : null,
      };
    });

    handleSuccess(res, 200, "Entrenadores para gestión obtenidos", entrenadoresConPerfil);
  } catch (error) {
    console.error("Error al obtener entrenadores para gestión:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * @name actualizarFotoEntrenador
 * @description Actualiza la foto visible de un entrenador (solo directiva)
 */
export async function actualizarFotoEntrenador(req, res) {
  try {
    const { rut } = req.params;

    if (!rut || typeof rut !== "string" || rut.trim().length < 5) {
      deleteIfExists(req.file?.path);
      return handleErrorClient(res, 400, "RUT del entrenador requerido");
    }

    if (!req.file) {
      return handleErrorClient(
        res,
        400,
        "Archivo requerido",
        "Debes adjuntar una imagen en formato válido.",
      );
    }

    const entrenador = await userRepository.findOne({ where: { rut } });
    if (!entrenador) {
      deleteIfExists(req.file.path);
      return handleErrorClient(res, 404, "Entrenador no encontrado");
    }

    if (entrenador.rol !== "entrenador") {
      deleteIfExists(req.file.path);
      return handleErrorClient(res, 400, "El usuario no corresponde a un entrenador");
    }

    let perfilPublico = await entrenadorPublicoRepository.findOne({
      where: { userRut: rut },
    });

    if (!perfilPublico) {
      perfilPublico = entrenadorPublicoRepository.create({
        userRut: rut,
        visible: true,
      });
    }

    try {
      await optimizeUploadedImage(req.file, {
        maxWidth: 800,
        maxHeight: 800,
        quality: 80,
      });
    } catch (error) {
      deleteIfExists(req.file.path);
      return handleErrorServer(res, 500, "Error procesando la imagen", error.message);
    }

    if (perfilPublico.fotoPath) {
      const previousPath = path.resolve(UPLOADS_BASE_PATH, perfilPublico.fotoPath);
      deleteIfExists(previousPath);
    }

    const relativePath = ensureRelativeUploadPath(req.file.path);

    perfilPublico.fotoPath = relativePath;
    perfilPublico.fotoVersion = (perfilPublico.fotoVersion ?? 0) + 1;
    await entrenadorPublicoRepository.save(perfilPublico);

    const fotoUrl = buildPublicFileUrl(
      perfilPublico.fotoPath,
      perfilPublico.fotoVersion,
      req,
    );

    handleSuccess(res, 200, "Foto de entrenador actualizada", {
      rut,
      fotoUrl,
      perfilPublicoId: perfilPublico.id,
      fotoVersion: perfilPublico.fotoVersion,
    });
  } catch (error) {
    console.error("Error al actualizar foto de entrenador:", error);
    deleteIfExists(req.file?.path);
    handleErrorServer(res, 500, error.message);
  }
}
