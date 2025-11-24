"use strict";
import { AppDataSource } from "../config/configDb.js";
import Asistencia from "../entity/asistencia.entity.js";
import { handleErrorClient, handleErrorServer, handleSuccess } from "../handlers/responseHandlers.js";
import { resolveFileUrl, deleteFromS3 } from "../utils/storage.utils.js";
import { getEstudiantesByApoderadoService } from "../services/estudiante.service.js";

const asistenciaRepository = AppDataSource.getRepository(Asistencia);

export async function subirJustificanteAsistencia(req, res) {
  try {
    const { id } = req.params;
    const file = req.file;
    const { justificacion } = req.body || {};

    if (!id) {
      return handleErrorClient(res, 400, "ID de asistencia requerido");
    }

    // Cargar asistencia con su inscripción
    const asistencia = await asistenciaRepository
      .createQueryBuilder("asistencia")
      .leftJoinAndSelect("asistencia.inscripcion", "inscripcion")
      .where("asistencia.id = :id", { id })
      .getOne();

    if (!asistencia) {
      return handleErrorClient(res, 404, "Asistencia no encontrada");
    }

    // Verificar que el alumno pertenece a los dependientes del apoderado
    const apoderadoRut = req.user?.rut || "";
    const [dependientes] = await getEstudiantesByApoderadoService(apoderadoRut);
    const dependientesRut = Array.isArray(dependientes) ? dependientes.map((e) => e.rut) : [];
    const rutAlumno = asistencia.inscripcion?.rutAlumno;

    if (!rutAlumno || !dependientesRut.includes(rutAlumno)) {
      return handleErrorClient(res, 403, "No tienes permisos sobre este alumno");
    }

    // Si ya había un archivo y suben uno nuevo, eliminamos el anterior
    const hadPreviousFile = Boolean(asistencia.rutaJustificacion);
    const previousPath = asistencia.rutaJustificacion;

    if (file) {
      const fileLocation = file.location || file.path || file.key || null;
      asistencia.rutaJustificacion = fileLocation;
      asistencia.nombreArchivoJustificacion = file.originalname || null;
      asistencia.tipoArchivoJustificacion = file.mimetype || null;
      asistencia.tamanoArchivoJustificacion = file.size || null;
    }

    if (justificacion !== undefined) {
      asistencia.justificacion = justificacion || null;
    }

    asistencia.apoderadoEmailJustificacion = req.user?.email || asistencia.apoderadoEmailJustificacion || null;
    asistencia.estado = "justificado";
    asistencia.updatedAt = new Date();

    const guardado = await asistenciaRepository.save(asistencia);

    // Limpieza del archivo previo si corresponde (no bloquear respuesta si falla)
    if (file && hadPreviousFile && previousPath && previousPath !== guardado.rutaJustificacion) {
      try { await deleteFromS3(previousPath); } catch { /* noop */ }
    }

    const payload = {
      id: guardado.id,
      fecha: guardado.fecha,
      tipoActividad: guardado.tipoActividad,
      categoria: guardado.categoria,
      estado: guardado.estado,
      observaciones: guardado.observaciones,
      justificacion: guardado.justificacion,
      archivoJustificacion: guardado.rutaJustificacion
        ? {
            url: resolveFileUrl(guardado.rutaJustificacion),
            nombre: guardado.nombreArchivoJustificacion,
            tipo: guardado.tipoArchivoJustificacion,
            tamano: guardado.tamanoArchivoJustificacion,
          }
        : null,
      inscripcion: guardado.inscripcion
        ? {
            id: guardado.inscripcion.id,
            codigoAlumno: guardado.inscripcion.codigoAlumno,
            nombreCompleto: `${guardado.inscripcion.nombre} ${guardado.inscripcion.apellidos}`.trim(),
            rutAlumno: guardado.inscripcion.rutAlumno,
            categoria: guardado.inscripcion.categoria || null,
          }
        : null,
    };

    return handleSuccess(res, 200, "Justificante registrado", payload);
  } catch (error) {
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerJustificacionesApoderado(req, res) {
  try {
    const apoderadoRut = req.user?.rut || "";
    const { pagina = 1, limite = 20, estado } = req.query;

    const take = Math.min(Number(limite) || 20, 100);
    const page = Math.max(Number(pagina) || 1, 1);
    const skip = (page - 1) * take;

    const allowedStates = ["justificado", "ausente", "tardanza"];
    const estadoFiltro = !!estado && allowedStates.includes(String(estado));
    // Obtener RUTs de hijos (dependientes) del apoderado
    const [dependientes] = await getEstudiantesByApoderadoService(apoderadoRut);
    const dependientesRut = Array.isArray(dependientes)
      ? dependientes.map((e) => e.rut).filter(Boolean)
      : [];

    const qb = asistenciaRepository
      .createQueryBuilder("asistencia")
      .leftJoinAndSelect("asistencia.inscripcion", "inscripcion")
      .leftJoinAndSelect("asistencia.marcadoPor", "marcadoPor")
      .where(dependientesRut.length ? "inscripcion.rutAlumno IN (:...ruts)" : "1=0", { ruts: dependientesRut });

    if (estadoFiltro) {
      qb.andWhere("asistencia.estado = :estado", { estado });
    } else {
      qb.andWhere("asistencia.estado IN (:...estados)", { estados: allowedStates });
    }

    qb.orderBy("asistencia.fecha", "DESC").addOrderBy("asistencia.createdAt", "DESC");

    const [registros, total] = await qb.take(take).skip(skip).getManyAndCount();

    const data = registros.map((item) => ({
      id: item.id,
      fecha: item.fecha,
      tipoActividad: item.tipoActividad,
      categoria: item.categoria,
      estado: item.estado,
      observaciones: item.observaciones,
      justificacion: item.justificacion,
      archivoJustificacion: item.rutaJustificacion
        ? {
            url: resolveFileUrl(item.rutaJustificacion),
            nombre: item.nombreArchivoJustificacion,
            tipo: item.tipoArchivoJustificacion,
            tamano: item.tamanoArchivoJustificacion,
          }
        : null,
      inscripcion: item.inscripcion
        ? {
            id: item.inscripcion.id,
            codigoAlumno: item.inscripcion.codigoAlumno,
            nombreCompleto: `${item.inscripcion.nombre} ${item.inscripcion.apellidos}`.trim(),
            rutAlumno: item.inscripcion.rutAlumno,
            categoria: item.inscripcion.categoria || null,
          }
        : null,
      marcadoPor: item.marcadoPor
        ? {
            rut: item.marcadoPor.rut,
            nombreCompleto: item.marcadoPor.nombreCompleto,
            rol: item.marcadoPor.rol,
          }
        : null,
    }));

    handleSuccess(res, 200, "Justificaciones obtenidas", {
      justificaciones: data,
      paginacion: {
        total,
        pagina: page,
        limite: take,
        totalPaginas: Math.max(Math.ceil(total / take), 1),
      },
    });
  } catch (error) {
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener asistencias pendientes de justificación del apoderado
export async function obtenerAsistenciasPendientesJustificacion(req, res) {
  try {
    const apoderadoRut = req.user?.rut || "";
    const { limite = 50 } = req.query;
    const take = Math.min(Number(limite) || 50, 100);

    // Obtener RUTs de hijos del apoderado
    const [dependientes] = await getEstudiantesByApoderadoService(apoderadoRut);
    const dependientesRut = Array.isArray(dependientes)
      ? dependientes.map((e) => e.rut).filter(Boolean)
      : [];

    if (!dependientesRut.length) {
      return handleSuccess(res, 200, "No hay estudiantes asignados", {
        asistencias: [],
        total: 0,
      });
    }

    // Buscar asistencias ausentes o tardanzas sin justificar
    const qb = asistenciaRepository
      .createQueryBuilder("asistencia")
      .leftJoinAndSelect("asistencia.inscripcion", "inscripcion")
      .where("inscripcion.rutAlumno IN (:...ruts)", { ruts: dependientesRut })
      .andWhere("asistencia.estado IN (:...estados)", { estados: ["ausente", "tardanza"] })
      .andWhere("(asistencia.justificacion IS NULL OR asistencia.justificacion = '')")
      .orderBy("asistencia.fecha", "DESC")
      .take(take);

    const asistencias = await qb.getMany();

    const data = asistencias.map((item) => ({
      id: item.id,
      fecha: item.fecha,
      tipoActividad: item.tipoActividad,
      categoria: item.categoria,
      estado: item.estado,
      observaciones: item.observaciones,
      inscripcion: item.inscripcion
        ? {
            id: item.inscripcion.id,
            codigoAlumno: item.inscripcion.codigoAlumno,
            nombreCompleto: `${item.inscripcion.nombre} ${item.inscripcion.apellidos}`.trim(),
            rutAlumno: item.inscripcion.rutAlumno,
            categoria: item.inscripcion.categoria || null,
          }
        : null,
    }));

    handleSuccess(res, 200, "Asistencias pendientes obtenidas", {
      asistencias: data,
      total: data.length,
    });
  } catch (error) {
    console.error("Error obteniendo asistencias pendientes:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
