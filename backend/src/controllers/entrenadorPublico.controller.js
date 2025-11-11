"use strict";
import { AppDataSource } from "../config/configDb.js";
import EntrenadorPublico from "../entity/entrenadorPublico.entity.js";
import User from "../entity/user.entity.js";
import { handleErrorClient, handleErrorServer, handleSuccess } from "../handlers/responseHandlers.js";

const entrenadorPublicoRepository = AppDataSource.getRepository(EntrenadorPublico);
const userRepository = AppDataSource.getRepository(User);

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
    const entrenadoresFormateados = entrenadores.map((entrenador) => ({
      id: entrenador.id,
      nombreCompleto: entrenador.user?.nombreCompleto || "Sin nombre",
      email: entrenador.user?.email,
      avatar: entrenador.user?.avatarPath 
        ? `${process.env.BASE_URL || 'http://localhost:3000'}/uploads/avatars/${entrenador.user.avatarPath}?v=${entrenador.user.avatarVersion || 0}`
        : null,
      titulo: entrenador.titulo,
      especialidad: entrenador.especialidad,
      aniosExperiencia: entrenador.aniosExperiencia,
      certificaciones: entrenador.certificaciones,
      logros: entrenador.logros,
      biografia: entrenador.biografia,
      categorias: entrenador.categorias,
      ordenVisualizacion: entrenador.ordenVisualizacion,
    }));

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
      avatar: entrenador.user?.avatarPath 
        ? `${process.env.BASE_URL || 'http://localhost:3000'}/uploads/avatars/${entrenador.user.avatarPath}?v=${entrenador.user.avatarVersion || 0}`
        : null,
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
    const {
      userRut,
      titulo,
      especialidad,
      aniosExperiencia,
      certificaciones,
      logros,
      biografia,
      categorias,
      visible,
      ordenVisualizacion,
    } = req.body;

    if (!userRut) {
      return handleErrorClient(res, 400, "El RUT del usuario es requerido");
    }

    // Verificar que el usuario existe y es entrenador
    const usuario = await userRepository.findOne({ where: { rut: userRut } });
    if (!usuario) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    if (usuario.rol !== "entrenador") {
      return handleErrorClient(res, 400, "El usuario debe tener rol de entrenador");
    }

    // Verificar si ya existe un perfil público para este entrenador
    let entrenador = await entrenadorPublicoRepository.findOne({
      where: { userRut },
    });

    if (entrenador) {
      // Actualizar perfil existente
      entrenador.titulo = titulo ?? entrenador.titulo;
      entrenador.especialidad = especialidad ?? entrenador.especialidad;
      entrenador.aniosExperiencia = aniosExperiencia ?? entrenador.aniosExperiencia;
      entrenador.certificaciones = certificaciones ?? entrenador.certificaciones;
      entrenador.logros = logros ?? entrenador.logros;
      entrenador.biografia = biografia ?? entrenador.biografia;
      entrenador.categorias = categorias ?? entrenador.categorias;
      entrenador.visible = visible !== undefined ? visible : entrenador.visible;
      entrenador.ordenVisualizacion = ordenVisualizacion ?? entrenador.ordenVisualizacion;

      await entrenadorPublicoRepository.save(entrenador);
      handleSuccess(res, 200, "Perfil público de entrenador actualizado", entrenador);
    } else {
      // Crear nuevo perfil
      const nuevoEntrenador = entrenadorPublicoRepository.create({
        userRut,
        titulo,
        especialidad,
        aniosExperiencia,
        certificaciones,
        logros,
        biografia,
        categorias,
        visible: visible !== undefined ? visible : true,
        ordenVisualizacion: ordenVisualizacion ?? 0,
      });

      await entrenadorPublicoRepository.save(nuevoEntrenador);
      handleSuccess(res, 201, "Perfil público de entrenador creado", nuevoEntrenador);
    }
  } catch (error) {
    console.error("Error al crear/actualizar entrenador público:", error);
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
    const updateData = req.body;

    const entrenador = await entrenadorPublicoRepository.findOne({
      where: { id: parseInt(id) },
    });

    if (!entrenador) {
      return handleErrorClient(res, 404, "Entrenador no encontrado");
    }

    // Actualizar campos
    Object.keys(updateData).forEach((key) => {
      if (updateData[key] !== undefined && key !== "id" && key !== "userRut") {
        entrenador[key] = updateData[key];
      }
    });

    await entrenadorPublicoRepository.save(entrenador);
    handleSuccess(res, 200, "Entrenador público actualizado", entrenador);
  } catch (error) {
    console.error("Error al actualizar entrenador público:", error);
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
      return {
        rut: entrenador.rut,
        nombreCompleto: entrenador.nombreCompleto,
        email: entrenador.email,
        avatar: entrenador.avatarPath 
          ? `${process.env.BASE_URL || 'http://localhost:3000'}/uploads/avatars/${entrenador.avatarPath}?v=${entrenador.avatarVersion || 0}`
          : null,
        tienePerfil: !!perfilPublico,
        perfilPublico: perfilPublico || null,
      };
    });

    handleSuccess(res, 200, "Entrenadores para gestión obtenidos", entrenadoresConPerfil);
  } catch (error) {
    console.error("Error al obtener entrenadores para gestión:", error);
    handleErrorServer(res, 500, error.message);
  }
}
