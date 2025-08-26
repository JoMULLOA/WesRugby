"use strict";
import Directiva from "../entity/directiva.entity.js";
import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const directivaRepository = AppDataSource.getRepository(Directiva);
const userRepository = AppDataSource.getRepository(User);

// Crear miembro de directiva (Solo Directiva)
export async function crearMiembroDirectiva(req, res) {
  try {
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede agregar miembros");
    }

    const {
      rut,
      cargo,
      descripcionCargo,
      fechaInicio,
      fechaFin,
      telefono,
      email,
      direccion,
      fechaNacimiento,
      experienciaAnterior,
      observaciones,
      activo = true
    } = req.body;

    // Verificar que el usuario existe
    const usuario = await userRepository.findOneBy({ rut });
    if (!usuario) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    // Verificar que no exista ya un miembro activo con el mismo cargo
    const cargoExistente = await directivaRepository.findOne({
      where: { cargo, activo: true }
    });

    if (cargoExistente && cargo !== "vocal") { // Puede haber múltiples vocales
      return handleErrorClient(res, 400, "Cargo ocupado", 
        `Ya existe un miembro activo con el cargo ${cargo}`);
    }

    // Verificar que el usuario no esté ya en directiva activa
    const miembroExistente = await directivaRepository.findOne({
      where: { rut, activo: true }
    });

    if (miembroExistente) {
      return handleErrorClient(res, 400, "Miembro existente", 
        "El usuario ya es miembro activo de la directiva");
    }

    const nuevoMiembro = directivaRepository.create({
      rut,
      cargo,
      descripcionCargo,
      fechaInicio,
      fechaFin,
      telefono,
      email,
      direccion,
      fechaNacimiento,
      experienciaAnterior,
      observaciones,
      activo,
      registradoPorRut: req.user.rut
    });

    const miembroGuardado = await directivaRepository.save(nuevoMiembro);

    const miembroCompleto = await directivaRepository.findOne({
      where: { id: miembroGuardado.id },
      relations: ["usuario", "registradoPor"]
    });

    handleSuccess(res, 201, "Miembro de directiva creado exitosamente", miembroCompleto);

  } catch (error) {
    console.error("Error creando miembro directiva:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener miembros de directiva
export async function obtenerMiembrosDirectiva(req, res) {
  try {
    const userRole = req.user.rol;
    const { activo, cargo, periodo } = req.query;

    // Solo roles administrativos pueden ver información completa
    const puedeVerCompleto = ["directiva", "tesorera"].includes(userRole);

    let whereCondition = {};

    if (activo !== undefined) {
      whereCondition.activo = activo === 'true';
    }

    if (cargo) {
      whereCondition.cargo = cargo;
    }

    // Para otros roles, solo mostrar miembros activos
    if (!puedeVerCompleto) {
      whereCondition.activo = true;
    }

    const miembros = await directivaRepository.find({
      where: whereCondition,
      relations: ["usuario"],
      order: { cargo: "ASC", fechaInicio: "DESC" }
    });

    // Filtrar información sensible para roles no administrativos
    if (!puedeVerCompleto) {
      miembros.forEach(miembro => {
        delete miembro.telefono;
        delete miembro.email;
        delete miembro.direccion;
        delete miembro.fechaNacimiento;
        delete miembro.experienciaAnterior;
        delete miembro.observaciones;
        delete miembro.registradoPor;
      });
    }

    handleSuccess(res, 200, "Miembros de directiva obtenidos exitosamente", miembros);

  } catch (error) {
    console.error("Error obteniendo miembros:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener miembro de directiva por ID
export async function obtenerMiembroPorId(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    const miembro = await directivaRepository.findOne({
      where: { id },
      relations: ["usuario", "registradoPor"]
    });

    if (!miembro) {
      return handleErrorClient(res, 404, "Miembro de directiva no encontrado");
    }

    // Solo roles administrativos pueden ver información completa
    const puedeVerCompleto = ["directiva", "tesorera"].includes(userRole);

    if (!puedeVerCompleto) {
      delete miembro.telefono;
      delete miembro.email;
      delete miembro.direccion;
      delete miembro.fechaNacimiento;
      delete miembro.experienciaAnterior;
      delete miembro.observaciones;
      delete miembro.registradoPor;
    }

    handleSuccess(res, 200, "Miembro de directiva obtenido exitosamente", miembro);

  } catch (error) {
    console.error("Error obteniendo miembro:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar miembro de directiva (Solo Directiva)
export async function actualizarMiembroDirectiva(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede actualizar miembros");
    }

    const miembro = await directivaRepository.findOneBy({ id });
    if (!miembro) {
      return handleErrorClient(res, 404, "Miembro de directiva no encontrado");
    }

    const datosActualizacion = req.body;

    // Verificar cambio de cargo si aplica
    if (datosActualizacion.cargo && datosActualizacion.cargo !== miembro.cargo) {
      const cargoExistente = await directivaRepository.findOne({
        where: { 
          cargo: datosActualizacion.cargo, 
          activo: true,
          id: { $ne: id } // Excluir el miembro actual
        }
      });

      if (cargoExistente && datosActualizacion.cargo !== "vocal") {
        return handleErrorClient(res, 400, "Cargo ocupado", 
          `Ya existe un miembro activo con el cargo ${datosActualizacion.cargo}`);
      }
    }

    // Campos permitidos para actualización
    const camposPermitidos = [
      'cargo', 'descripcionCargo', 'fechaFin', 'telefono', 'email',
      'direccion', 'experienciaAnterior', 'observaciones', 'activo'
    ];

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        miembro[campo] = datosActualizacion[campo];
      }
    });

    miembro.updatedAt = new Date();
    
    const miembroActualizado = await directivaRepository.save(miembro);

    const miembroCompleto = await directivaRepository.findOne({
      where: { id: miembroActualizado.id },
      relations: ["usuario", "registradoPor"]
    });

    handleSuccess(res, 200, "Miembro de directiva actualizado exitosamente", miembroCompleto);

  } catch (error) {
    console.error("Error actualizando miembro:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Desactivar miembro de directiva (Solo Directiva)
export async function desactivarMiembroDirectiva(req, res) {
  try {
    const { id } = req.params;
    const { motivoCese } = req.body;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede desactivar miembros");
    }

    const miembro = await directivaRepository.findOneBy({ id });
    if (!miembro) {
      return handleErrorClient(res, 404, "Miembro de directiva no encontrado");
    }

    // No permitir que se desactive a sí mismo si es el único directiva
    if (miembro.rut === req.user.rut) {
      const otrosDirectiva = await directivaRepository.count({
        where: { 
          cargo: "presidente",
          activo: true,
          id: { $ne: id }
        }
      });

      if (otrosDirectiva === 0) {
        return handleErrorClient(res, 400, "Acción no permitida", 
          "No puede desactivarse siendo el único presidente activo");
      }
    }

    miembro.activo = false;
    miembro.fechaFin = new Date();
    miembro.motivoCese = motivoCese;
    miembro.updatedAt = new Date();
    
    const miembroDesactivado = await directivaRepository.save(miembro);

    const miembroCompleto = await directivaRepository.findOne({
      where: { id: miembroDesactivado.id },
      relations: ["usuario"]
    });

    handleSuccess(res, 200, "Miembro de directiva desactivado exitosamente", miembroCompleto);

  } catch (error) {
    console.error("Error desactivando miembro:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estructura organizacional actual
export async function obtenerEstructuraOrganizacional(req, res) {
  try {
    const miembrosActivos = await directivaRepository.find({
      where: { activo: true },
      relations: ["usuario"],
      order: { cargo: "ASC" }
    });

    // Agrupar por cargo
    const estructura = miembrosActivos.reduce((acc, miembro) => {
      if (!acc[miembro.cargo]) {
        acc[miembro.cargo] = [];
      }
      acc[miembro.cargo].push(miembro);
      return acc;
    }, {});

    // Definir jerarquía de cargos
    const jerarquia = [
      "presidente",
      "vicepresidente", 
      "secretario",
      "tesorero",
      "vocal",
      "asesor"
    ];

    const estructuraOrdenada = {};
    jerarquia.forEach(cargo => {
      if (estructura[cargo]) {
        estructuraOrdenada[cargo] = estructura[cargo];
      }
    });

    // Agregar cualquier cargo no contemplado en la jerarquía
    Object.keys(estructura).forEach(cargo => {
      if (!jerarquia.includes(cargo)) {
        estructuraOrdenada[cargo] = estructura[cargo];
      }
    });

    handleSuccess(res, 200, "Estructura organizacional obtenida exitosamente", {
      totalMiembros: miembrosActivos.length,
      estructura: estructuraOrdenada
    });

  } catch (error) {
    console.error("Error obteniendo estructura:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener historial de directiva
export async function obtenerHistorialDirectiva(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { año, cargo } = req.query;

    let whereCondition = {};

    if (año) {
      whereCondition.fechaInicio = {
        $gte: `${año}-01-01`,
        $lte: `${año}-12-31`
      };
    }

    if (cargo) {
      whereCondition.cargo = cargo;
    }

    const historial = await directivaRepository.find({
      where: whereCondition,
      relations: ["usuario", "registradoPor"],
      order: { fechaInicio: "DESC", cargo: "ASC" }
    });

    handleSuccess(res, 200, "Historial de directiva obtenido exitosamente", historial);

  } catch (error) {
    console.error("Error obteniendo historial:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estadísticas de directiva
export async function obtenerEstadisticasDirectiva(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const totalMiembros = await directivaRepository.count();
    const miembrosActivos = await directivaRepository.count({ 
      where: { activo: true } 
    });
    const miembrosInactivos = await directivaRepository.count({ 
      where: { activo: false } 
    });

    // Miembros por cargo
    const porCargo = await directivaRepository
      .createQueryBuilder("directiva")
      .select("directiva.cargo", "cargo")
      .addSelect("COUNT(*)", "cantidad")
      .where("directiva.activo = true")
      .groupBy("directiva.cargo")
      .getRawMany();

    // Duración promedio de mandatos
    const duracionMandatos = await directivaRepository
      .createQueryBuilder("directiva")
      .select("AVG(DATEDIFF(COALESCE(directiva.fechaFin, NOW()), directiva.fechaInicio))", "promediodias")
      .where("directiva.fechaFin IS NOT NULL")
      .getRawOne();

    // Renovación por año
    const renovacionAnual = await directivaRepository
      .createQueryBuilder("directiva")
      .select("YEAR(directiva.fechaInicio)", "año")
      .addSelect("COUNT(*)", "nuevosmiembros")
      .groupBy("año")
      .orderBy("año", "DESC")
      .limit(5)
      .getRawMany();

    const estadisticas = {
      resumen: {
        totalMiembros,
        miembrosActivos,
        miembrosInactivos
      },
      distribucion: {
        porCargo
      },
      tendencias: {
        duracionPromediaDias: duracionMandatos?.promedioidas || 0,
        renovacionAnual
      }
    };

    handleSuccess(res, 200, "Estadísticas de directiva obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Transferir cargo (Solo Directiva)
export async function transferirCargo(req, res) {
  try {
    const { idActual, rutNuevo } = req.body;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const miembroActual = await directivaRepository.findOneBy({ 
      id: idActual, 
      activo: true 
    });

    if (!miembroActual) {
      return handleErrorClient(res, 404, "Miembro actual no encontrado");
    }

    const nuevoUsuario = await userRepository.findOneBy({ rut: rutNuevo });
    if (!nuevoUsuario) {
      return handleErrorClient(res, 404, "Nuevo usuario no encontrado");
    }

    // Verificar que el nuevo usuario no esté ya en directiva activa
    const yaEsMiembro = await directivaRepository.findOne({
      where: { rut: rutNuevo, activo: true }
    });

    if (yaEsMiembro) {
      return handleErrorClient(res, 400, "Usuario ya es miembro activo");
    }

    // Desactivar miembro actual
    miembroActual.activo = false;
    miembroActual.fechaFin = new Date();
    miembroActual.motivoCese = "Transferencia de cargo";
    await directivaRepository.save(miembroActual);

    // Crear nuevo miembro
    const nuevoMiembro = directivaRepository.create({
      rut: rutNuevo,
      cargo: miembroActual.cargo,
      descripcionCargo: miembroActual.descripcionCargo,
      fechaInicio: new Date(),
      activo: true,
      registradoPorRut: req.user.rut
    });

    const miembroCreado = await directivaRepository.save(nuevoMiembro);

    const miembroCompleto = await directivaRepository.findOne({
      where: { id: miembroCreado.id },
      relations: ["usuario", "registradoPor"]
    });

    handleSuccess(res, 200, "Cargo transferido exitosamente", {
      miembroAnterior: miembroActual,
      miembroNuevo: miembroCompleto
    });

  } catch (error) {
    console.error("Error transfiriendo cargo:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
