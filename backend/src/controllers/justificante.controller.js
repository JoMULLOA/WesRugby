"use strict";
import { AppDataSource } from "../config/configDb.js";
import Justificante from "../entity/justificante.entity.js";
import { SesionAsistenciaSchema } from "../entity/sesionAsistencia.entity.js";
import { RegistroAsistenciaSchema } from "../entity/registroAsistencia.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { resolveFileUrl } from "../utils/storage.utils.js";

const justificanteRepository = AppDataSource.getRepository(Justificante);

function mapJustificante(j) {
  return {
    id: j.id,
    apoderadoRut: j.apoderadoRut,
    apoderadoEmail: j.apoderadoEmail,
    estudianteRut: j.estudianteRut,
    fechaInicio: j.fechaInicio,
    fechaFin: j.fechaFin,
    tipo: j.tipo,
    motivo: j.motivo,
    descripcion: j.descripcion,
    estado: j.estado,
    motivoRechazo: j.motivoRechazo,
    observacionesDirectiva: j.observacionesDirectiva,
    revisadoPorRut: j.revisadoPorRut,
    fechaRevision: j.fechaRevision,
    mesesExencion: Array.isArray(j.mesesExencion) ? j.mesesExencion : null,
    archivo: j.rutaArchivo
      ? {
          url: resolveFileUrl(j.rutaArchivo),
          nombre: j.nombreArchivoOriginal,
          tipo: j.tipoArchivo,
          tamano: j.tamanoArchivo,
        }
      : null,
    fechaSubida: j.fechaSubida,
    createdAt: j.createdAt,
    updatedAt: j.updatedAt,
  };
}

export async function crearJustificanteApoderado(req, res) {
  try {
    const rutApoderado = req.user?.rut || null;
    if (!rutApoderado)
      return handleErrorClient(res, 401, "Rut apoderado no disponible");
    const { estudianteRut, fechaInicio, fechaFin, tipo, motivo, descripcion } =
      req.body;
    if (!estudianteRut || !fechaInicio || !tipo || !motivo) {
      return handleErrorClient(res, 400, "Campos requeridos faltantes");
    }
    const file = req.file;
    const justificante = justificanteRepository.create({
      apoderadoRut: rutApoderado,
      apoderadoEmail: req.user?.email || null,
      estudianteRut,
      fechaInicio,
      fechaFin: fechaFin || null,
      tipo: String(tipo).trim().toLowerCase(),
      motivo,
      descripcion: descripcion || null,
      estado: "pendiente",
    });
    if (file) {
      justificante.rutaArchivo = file.location || file.path || file.key || null;
      justificante.nombreArchivoOriginal = file.originalname || null;
      justificante.tipoArchivo = file.mimetype || null;
      justificante.tamanoArchivo = file.size || null;
    }
    const saved = await justificanteRepository.save(justificante);
    handleSuccess(res, 201, "Justificante creado", mapJustificante(saved));
  } catch (error) {
    handleErrorServer(res, 500, "Error creando justificante", error.message);
  }
}

export async function listarJustificantesApoderado(req, res) {
  try {
    const rutApoderado = req.user?.rut || null;
    const { pagina = 1, limite = 20, estado } = req.query;
    const take = Math.min(Number(limite) || 20, 100);
    const page = Math.max(Number(pagina) || 1, 1);
    const skip = (page - 1) * take;
    const qb = justificanteRepository
      .createQueryBuilder("j")
      .where("j.apoderadoRut = :rut", { rut: rutApoderado });
    if (estado) qb.andWhere("j.estado = :estado", { estado });
    qb.orderBy("j.fechaSubida", "DESC").addOrderBy("j.createdAt", "DESC");
    const [rows, total] = await qb.take(take).skip(skip).getManyAndCount();
    handleSuccess(res, 200, "Justificantes apoderado", {
      justificantes: rows.map(mapJustificante),
      paginacion: {
        total,
        pagina: page,
        limite: take,
        totalPaginas: Math.max(Math.ceil(total / take), 1),
      },
    });
  } catch (error) {
    handleErrorServer(res, 500, "Error listando justificantes", error.message);
  }
}

export async function listarJustificantesDirectiva(req, res) {
  try {
    const {
      pagina = 1,
      limite = 30,
      estado,
      estudianteRut,
      apoderadoRut,
      desde,
      hasta,
    } = req.query;
    const take = Math.min(Number(limite) || 30, 100);
    const page = Math.max(Number(pagina) || 1, 1);
    const skip = (page - 1) * take;
    const qb = justificanteRepository.createQueryBuilder("j");
    if (estado) qb.where("j.estado = :estado", { estado });
    if (estudianteRut)
      qb.andWhere("j.estudianteRut = :estudianteRut", { estudianteRut });
    if (apoderadoRut)
      qb.andWhere("j.apoderadoRut = :apoderadoRut", { apoderadoRut });
    if (desde && hasta) {
      qb.andWhere(
        "j.fechaInicio <= :hasta AND (j.fechaFin IS NULL OR j.fechaFin >= :desde)",
        { desde, hasta },
      );
    } else if (desde) {
      qb.andWhere(
        "(j.fechaFin IS NULL AND j.fechaInicio = :desde) OR (j.fechaFin IS NOT NULL AND j.fechaFin >= :desde)",
        { desde },
      );
    }
    qb.orderBy("j.fechaInicio", "DESC").addOrderBy("j.createdAt", "DESC");
    const [rows, total] = await qb.take(take).skip(skip).getManyAndCount();
    handleSuccess(res, 200, "Justificantes para directiva", {
      justificantes: rows.map(mapJustificante),
      paginacion: {
        total,
        pagina: page,
        limite: take,
        totalPaginas: Math.max(Math.ceil(total / take), 1),
      },
    });
  } catch (error) {
    handleErrorServer(
      res,
      500,
      "Error listando justificantes directiva",
      error.message,
    );
  }
}

export async function actualizarEstadoJustificante(req, res) {
  try {
    const { id } = req.params;
    const { estado, motivoRechazo, observacionesDirectiva } = req.body;
    if (!id) return handleErrorClient(res, 400, "ID requerido");
    const justificante = await justificanteRepository.findOne({
      where: { id },
    });
    if (!justificante)
      return handleErrorClient(res, 404, "Justificante no encontrado");
    const allowed = ["pendiente", "aprobado", "rechazado", "observado"];
    if (estado && !allowed.includes(String(estado)))
      return handleErrorClient(res, 400, "Estado inválido");
    const nuevoEstado = estado ? String(estado) : justificante.estado;
    justificante.estado = nuevoEstado;
    justificante.motivoRechazo =
      nuevoEstado === "rechazado" ? motivoRechazo || null : null;
    justificante.observacionesDirectiva =
      observacionesDirectiva || justificante.observacionesDirectiva || null;
    justificante.revisadoPorRut =
      req.user?.rut || justificante.revisadoPorRut || null;
    justificante.fechaRevision = new Date();

    if (nuevoEstado === "aprobado") {
      try {
        const fechaInicio = justificante.fechaInicio;
        const fechaFin = justificante.fechaFin || justificante.fechaInicio;
        const sesionRepo = AppDataSource.getRepository(SesionAsistenciaSchema);
        const registroRepo = AppDataSource.getRepository(
          RegistroAsistenciaSchema,
        );
        const sesiones = await sesionRepo
          .createQueryBuilder("sesion")
          .where("sesion.fecha BETWEEN :fi AND :ff", {
            fi: fechaInicio,
            ff: fechaFin,
          })
          .getMany();
        if (sesiones.length) {
          const sesionIds = sesiones.map((s) => s.id);
          await registroRepo
            .createQueryBuilder()
            .update(RegistroAsistenciaSchema)
            .set({ estado: "justificado" })
            .where("rutEstudiante = :rut", { rut: justificante.estudianteRut })
            .andWhere("sesionId IN (:...ids)", { ids: sesionIds })
            .andWhere("estado != :actual", { actual: "justificado" })
            .execute();
        }
      } catch (e) {
        console.error(
          "⚠️ Error propagando justificación a registros asistencia:",
          e.message,
        );
      }
    }

    const saved = await justificanteRepository.save(justificante);
    handleSuccess(res, 200, "Estado actualizado", mapJustificante(saved));
  } catch (error) {
    handleErrorServer(res, 500, "Error actualizando estado", error.message);
  }
}

export async function actualizarMesesExencion(req, res) {
  try {
    const { id } = req.params;
    const { meses } = req.body || {};
    if (!id) return handleErrorClient(res, 400, "ID requerido");
    const justificante = await justificanteRepository.findOne({
      where: { id },
    });
    if (!justificante)
      return handleErrorClient(res, 404, "Justificante no encontrado");
    if (justificante.estado !== "aprobado") {
      return handleErrorClient(
        res,
        409,
        "Solo justificantes aprobados pueden tener meses de exención",
      );
    }
    if (!Array.isArray(meses))
      return handleErrorClient(res, 400, "meses debe ser un array");
    const formato = /^\d{4}-\d{2}$/;
    const mesesNormalizados = meses.map((m) => String(m).trim());
    if (!mesesNormalizados.every((m) => formato.test(m))) {
      return handleErrorClient(res, 400, "Formato inválido. Use YYYY-MM");
    }
    // Limitar meses al rango del justificante
    const fi = new Date(justificante.fechaInicio);
    const ff = new Date(justificante.fechaFin || justificante.fechaInicio);
    const mesesRango = [];
    const cursor = new Date(fi.getFullYear(), fi.getMonth(), 1);
    const limite = new Date(ff.getFullYear(), ff.getMonth(), 1);
    while (cursor <= limite) {
      const mm = String(cursor.getMonth() + 1).padStart(2, "0");
      mesesRango.push(`${cursor.getFullYear()}-${mm}`);
      cursor.setMonth(cursor.getMonth() + 1);
    }
    const filtrados = mesesNormalizados.filter((m) => mesesRango.includes(m));
    justificante.mesesExencion = filtrados;
    justificante.updatedAt = new Date();
    const saved = await justificanteRepository.save(justificante);
    handleSuccess(
      res,
      200,
      "Meses de exención actualizados",
      mapJustificante(saved),
    );
  } catch (error) {
    handleErrorServer(
      res,
      500,
      "Error actualizando meses exención",
      error.message,
    );
  }
}

// Obtener justificantes aprobados que cubren una fecha para múltiples estudiantes
// GET /justificantes/fecha/:fecha?ruts=RUT1,RUT2
export async function obtenerJustificadosPorFecha(req, res) {
  try {
    const { fecha } = req.params;
    const { ruts } = req.query;
    if (!fecha) return handleErrorClient(res, 400, "Fecha requerida");
    const fechaISO = new Date(fecha);
    if (isNaN(fechaISO.getTime()))
      return handleErrorClient(res, 400, "Fecha inválida");
    const listaRuts =
      typeof ruts === "string"
        ? ruts
            .split(",")
            .map((r) => r.trim())
            .filter(Boolean)
        : [];
    if (!listaRuts.length)
      return handleErrorClient(res, 400, "RUTs requeridos");
    const justificantes = await justificanteRepository
      .createQueryBuilder("j")
      .where("j.estado = 'aprobado'")
      .andWhere("j.estudianteRut IN (:...ruts)", { ruts: listaRuts })
      .andWhere(
        "j.fechaInicio <= :fecha AND (j.fechaFin IS NULL OR j.fechaFin >= :fecha)",
        { fecha },
      )
      .getMany();
    const agrupados = listaRuts.map((rut) => ({
      estudianteRut: rut,
      justificantes: justificantes
        .filter((j) => j.estudianteRut === rut)
        .map(mapJustificante),
    }));
    handleSuccess(res, 200, "Justificantes aprobados por fecha", {
      fecha,
      estudiantes: agrupados,
    });
  } catch (error) {
    handleErrorServer(
      res,
      500,
      "Error obteniendo justificantes por fecha",
      error.message,
    );
  }
}
