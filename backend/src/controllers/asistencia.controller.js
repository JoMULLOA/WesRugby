"use strict";
import Asistencia from "../entity/asistencia.entity.js";
import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const asistenciaRepository = AppDataSource.getRepository(Asistencia);
const userRepository = AppDataSource.getRepository(User);

// Registrar asistencia (Entrenador, Directiva)
export async function registrarAsistencia(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["entrenador", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo entrenadores y directiva pueden registrar asistencia");
    }

    const {
      rutJugador,
      tipoActividad,
      categoria,
      fecha,
      horaInicio,
      horaFin,
      lugar,
      descripcionActividad,
      observaciones,
      clima,
      estado = "presente"
    } = req.body;

    // Verificar que el jugador existe
    const jugador = await userRepository.findOneBy({ rut: rutJugador });
    if (!jugador) {
      return handleErrorClient(res, 404, "Jugador no encontrado");
    }

    // Verificar que no exista ya una asistencia para la misma fecha y actividad
    const asistenciaExistente = await asistenciaRepository.findOne({
      where: {
        rutJugador,
        fecha,
        tipoActividad,
        categoria
      }
    });

    if (asistenciaExistente) {
      return handleErrorClient(res, 400, "Asistencia duplicada", 
        "Ya existe un registro de asistencia para este jugador en esta fecha y actividad");
    }

    const nuevaAsistencia = asistenciaRepository.create({
      rutJugador,
      tipoActividad,
      categoria,
      fecha,
      horaInicio,
      horaFin,
      lugar,
      descripcionActividad,
      observaciones,
      clima,
      estado,
      registradoPorRut: req.user.rut
    });

    const asistenciaGuardada = await asistenciaRepository.save(nuevaAsistencia);

    const asistenciaCompleta = await asistenciaRepository.findOne({
      where: { id: asistenciaGuardada.id },
      relations: ["jugador", "registradoPor"]
    });

    handleSuccess(res, 201, "Asistencia registrada exitosamente", asistenciaCompleta);

  } catch (error) {
    console.error("Error registrando asistencia:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener asistencias con filtros
export async function obtenerAsistencias(req, res) {
  try {
    const userRole = req.user.rol;
    const userRut = req.user.rut;
    const {
      fecha,
      fechaInicio,
      fechaFin,
      rutJugador,
      categoria,
      tipoActividad,
      estado,
      limite = 50,
      pagina = 1
    } = req.query;

    let whereCondition = {};

    // Filtro por rol
    if (userRole === "apoderado") {
      // Apoderados solo ven asistencias de sus hijos
      const hijos = await userRepository.find({
        where: { rutApoderado: userRut }
      });
      
      if (hijos.length === 0) {
        return handleSuccess(res, 200, "Asistencias obtenidas", []);
      }

      const rutsHijos = hijos.map(hijo => hijo.rut);
      whereCondition.rutJugador = { $in: rutsHijos };
    } else if (rutJugador) {
      whereCondition.rutJugador = rutJugador;
    }

    // Aplicar filtros
    if (fecha) {
      whereCondition.fecha = fecha;
    }

    if (fechaInicio && fechaFin) {
      whereCondition.fecha = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    if (categoria) {
      whereCondition.categoria = categoria;
    }

    if (tipoActividad) {
      whereCondition.tipoActividad = tipoActividad;
    }

    if (estado) {
      whereCondition.estado = estado;
    }

    const skip = (parseInt(pagina) - 1) * parseInt(limite);

    const [asistencias, total] = await asistenciaRepository.findAndCount({
      where: whereCondition,
      relations: ["jugador", "registradoPor"],
      order: { fecha: "DESC", horaInicio: "DESC" },
      take: parseInt(limite),
      skip: skip
    });

    const resultado = {
      asistencias,
      paginacion: {
        total,
        pagina: parseInt(pagina),
        limite: parseInt(limite),
        totalPaginas: Math.ceil(total / parseInt(limite))
      }
    };

    handleSuccess(res, 200, "Asistencias obtenidas exitosamente", resultado);

  } catch (error) {
    console.error("Error obteniendo asistencias:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar asistencia (Entrenador, Directiva)
export async function actualizarAsistencia(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (!["entrenador", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo entrenadores y directiva pueden actualizar asistencia");
    }

    const asistencia = await asistenciaRepository.findOneBy({ id });
    if (!asistencia) {
      return handleErrorClient(res, 404, "Registro de asistencia no encontrado");
    }

    const datosActualizacion = req.body;

    // Campos permitidos para actualización
    const camposPermitidos = [
      'estado', 'horaInicio', 'horaFin', 'observaciones', 'clima',
      'descripcionActividad', 'lugar'
    ];

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        asistencia[campo] = datosActualizacion[campo];
      }
    });

    asistencia.updatedAt = new Date();
    
    const asistenciaActualizada = await asistenciaRepository.save(asistencia);

    const asistenciaCompleta = await asistenciaRepository.findOne({
      where: { id: asistenciaActualizada.id },
      relations: ["jugador", "registradoPor"]
    });

    handleSuccess(res, 200, "Asistencia actualizada exitosamente", asistenciaCompleta);

  } catch (error) {
    console.error("Error actualizando asistencia:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Registrar asistencia masiva (Entrenador, Directiva)
export async function registrarAsistenciaMasiva(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["entrenador", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const {
      tipoActividad,
      categoria,
      fecha,
      horaInicio,
      horaFin,
      lugar,
      descripcionActividad,
      clima,
      jugadores // Array de { rut, estado, observaciones? }
    } = req.body;

    if (!jugadores || jugadores.length === 0) {
      return handleErrorClient(res, 400, "Lista de jugadores requerida");
    }

    const asistenciasCreadas = [];
    const errores = [];

    for (const jugadorData of jugadores) {
      try {
        // Verificar que el jugador existe
        const jugador = await userRepository.findOneBy({ rut: jugadorData.rut });
        if (!jugador) {
          errores.push(`Jugador con RUT ${jugadorData.rut} no encontrado`);
          continue;
        }

        // Verificar duplicados
        const asistenciaExistente = await asistenciaRepository.findOne({
          where: {
            rutJugador: jugadorData.rut,
            fecha,
            tipoActividad,
            categoria
          }
        });

        if (asistenciaExistente) {
          errores.push(`Ya existe asistencia para ${jugador.nombres} ${jugador.apellidos}`);
          continue;
        }

        const nuevaAsistencia = asistenciaRepository.create({
          rutJugador: jugadorData.rut,
          tipoActividad,
          categoria,
          fecha,
          horaInicio,
          horaFin,
          lugar,
          descripcionActividad,
          clima,
          estado: jugadorData.estado || "presente",
          observaciones: jugadorData.observaciones,
          registradoPorRut: req.user.rut
        });

        const asistenciaGuardada = await asistenciaRepository.save(nuevaAsistencia);
        asistenciasCreadas.push(asistenciaGuardada);

      } catch (error) {
        errores.push(`Error procesando ${jugadorData.rut}: ${error.message}`);
      }
    }

    const resultado = {
      exitosas: asistenciasCreadas.length,
      errores: errores.length,
      detalleErrores: errores,
      asistencias: asistenciasCreadas
    };

    if (asistenciasCreadas.length > 0) {
      handleSuccess(res, 201, 
        `Asistencia masiva procesada: ${asistenciasCreadas.length} exitosas, ${errores.length} errores`, 
        resultado);
    } else {
      handleErrorClient(res, 400, "No se pudo registrar ninguna asistencia", resultado);
    }

  } catch (error) {
    console.error("Error en registro masivo:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estadísticas de asistencia
export async function obtenerEstadisticasAsistencia(req, res) {
  try {
    const userRole = req.user.rol;
    const userRut = req.user.rut;
    
    const { fechaInicio, fechaFin, categoria, rutJugador } = req.query;

    let whereCondition = {};

    // Filtros de fecha
    if (fechaInicio && fechaFin) {
      whereCondition.fecha = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    if (categoria) {
      whereCondition.categoria = categoria;
    }

    // Restricciones por rol
    if (userRole === "apoderado") {
      const hijos = await userRepository.find({
        where: { rutApoderado: userRut }
      });
      
      if (hijos.length === 0) {
        return handleSuccess(res, 200, "Estadísticas obtenidas", { mensaje: "No tiene hijos registrados" });
      }

      const rutsHijos = hijos.map(hijo => hijo.rut);
      whereCondition.rutJugador = { $in: rutsHijos };
    } else if (rutJugador) {
      whereCondition.rutJugador = rutJugador;
    }

    // Estadísticas generales
    const totalRegistros = await asistenciaRepository.count({ where: whereCondition });

    // Por estado
    const porEstado = await asistenciaRepository
      .createQueryBuilder("asistencia")
      .select("asistencia.estado", "estado")
      .addSelect("COUNT(*)", "cantidad")
      .where(whereCondition)
      .groupBy("asistencia.estado")
      .getRawMany();

    // Por tipo de actividad
    const porTipoActividad = await asistenciaRepository
      .createQueryBuilder("asistencia")
      .select("asistencia.tipoActividad", "tipo")
      .addSelect("COUNT(*)", "cantidad")
      .where(whereCondition)
      .groupBy("asistencia.tipoActividad")
      .getRawMany();

    // Por categoría
    const porCategoria = await asistenciaRepository
      .createQueryBuilder("asistencia")
      .select("asistencia.categoria", "categoria")
      .addSelect("COUNT(*)", "cantidad")
      .where(whereCondition)
      .groupBy("asistencia.categoria")
      .getRawMany();

    // Jugador con mejor asistencia (solo para entrenadores y directiva)
    let mejorAsistencia = null;
    if (["entrenador", "directiva"].includes(userRole)) {
      mejorAsistencia = await asistenciaRepository
        .createQueryBuilder("asistencia")
        .leftJoinAndSelect("asistencia.jugador", "jugador")
        .select("jugador.nombres", "nombres")
        .addSelect("jugador.apellidos", "apellidos")
        .addSelect("COUNT(CASE WHEN asistencia.estado = 'presente' THEN 1 END)", "presentes")
        .addSelect("COUNT(*)", "total")
        .where(whereCondition)
        .groupBy("jugador.rut")
        .orderBy("presentes", "DESC")
        .limit(1)
        .getRawOne();
    }

    const estadisticas = {
      resumen: {
        totalRegistros,
        porEstado,
        porTipoActividad,
        porCategoria
      },
      mejorAsistencia
    };

    handleSuccess(res, 200, "Estadísticas de asistencia obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Eliminar registro de asistencia (Solo Directiva)
export async function eliminarAsistencia(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede eliminar registros de asistencia");
    }

    const asistencia = await asistenciaRepository.findOneBy({ id });
    if (!asistencia) {
      return handleErrorClient(res, 404, "Registro de asistencia no encontrado");
    }

    await asistenciaRepository.remove(asistencia);

    handleSuccess(res, 200, "Registro de asistencia eliminado exitosamente");

  } catch (error) {
    console.error("Error eliminando asistencia:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
