"use strict";
import path from "path";
import fs from "fs";
import { AppDataSource } from "../config/configDb.js";
import EventoDeportivo from "../entity/eventoDeportivo.entity.js";
import ParticipacionEventoDeportivo from "../entity/participacionEventoDeportivo.entity.js";
import EventoMultimedia from "../entity/eventoMultimedia.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { optimizeUploadedImage } from "../utils/image.utils.js";
const eventoDeportivoRepository = AppDataSource.getRepository(EventoDeportivo);
const participacionDeportivaRepository = AppDataSource.getRepository(
  ParticipacionEventoDeportivo,
);
const multimediaRepository = AppDataSource.getRepository(EventoMultimedia);

const ACTIVE_STATES = ["programado", "confirmado", "en_curso"];

function isEventoFinalizado(evento) {
  if (!evento) {
    return false;
  }

  const fechaComparacion = evento.fechaFin || evento.fechaInicio;
  const fechaEvento = fechaComparacion
    ? new Date(fechaComparacion)
    : new Date();

  const ahora = new Date();
  const porEstado = evento.estado && !ACTIVE_STATES.includes(evento.estado);
  const porFecha = fechaEvento.getTime() < ahora.getTime();

  return porEstado || porFecha;
}

async function ensureEventoDeportivoFinalizado(eventoId) {
  const evento = await eventoDeportivoRepository.findOne({
    where: { id: eventoId },
  });

  if (!evento) {
    return {
      ok: false,
      error: {
        status: 404,
        message: "Evento deportivo no encontrado",
      },
    };
  }

  if (!isEventoFinalizado(evento)) {
    return {
      ok: false,
      error: {
        status: 400,
        message: "El evento aún no ha finalizado",
      },
    };
  }

  return {
    ok: true,
    evento,
  };
}

function cleanupUploadedFile(file) {
  if (file?.path && fs.existsSync(file.path)) {
    fs.unlinkSync(file.path);
  }
}

function getBaseUrl(req) {
  return `${req.protocol}://${req.get("host")}`;
}

function buildPublicUploadUrl(req, storagePath) {
  const normalizedPath = storagePath.replace(/\\/g, "/");
  return `${getBaseUrl(req)}/uploads/${normalizedPath}`;
}

function buildAvatarUrl(req, avatarPath, avatarVersion) {
  if (!avatarPath) return null;
  const normalized = avatarPath.replace(/\\/g, "/");
  const baseUrl = `${getBaseUrl(req)}/uploads/${normalized}`;
  if (typeof avatarVersion === "number" && !Number.isNaN(avatarVersion)) {
    return `${baseUrl}?v=${avatarVersion}`;
  }
  return baseUrl;
}

function resolveEventoIdForRoutes(media) {
  if (media.eventoDeportivoId) {
    return media.eventoDeportivoId;
  }
  if (media.eventoId !== undefined && media.eventoId !== null) {
    return String(media.eventoId);
  }
  return null;
}

function buildMediaPayload(media, req) {
  const url = buildPublicUploadUrl(req, media.storagePath);
  const routeEventoId = resolveEventoIdForRoutes(media);
  const routeSegment = routeEventoId
    ? encodeURIComponent(routeEventoId)
    : null;
  const viewUrl = routeSegment
    ? `${getBaseUrl(req)}/api/eventos-deportivos/${routeSegment}/multimedia/${media.id}`
    : null;
  const downloadUrl = routeSegment ? `${viewUrl}/download` : null;

  const uploader = media.uploader || null;
  const uploaderNombre =
    uploader?.nombreCompleto || media.uploadedByNombre || null;
  const uploaderEmail = uploader?.email || null;
  const uploaderRol = uploader?.rol || media.uploadedByRol || null;
  const uploaderRut = uploader?.rut || media.uploadedByRut || null;
  const avatarVersion =
    typeof uploader?.avatarVersion === "number"
      ? uploader.avatarVersion
      : null;
  const avatarUrl = uploader?.avatarPath
    ? buildAvatarUrl(req, uploader.avatarPath, avatarVersion ?? undefined)
    : null;

  const createdAtDate =
    media.createdAt instanceof Date
      ? media.createdAt
      : media.createdAt
        ? new Date(media.createdAt)
        : null;

  return {
    id: media.id,
    eventoDeportivoId: media.eventoDeportivoId,
    eventoId: media.eventoId,
    tituloEvento: media.tituloEvento,
    uploadedByRut: media.uploadedByRut,
    uploadedByNombre: media.uploadedByNombre,
    uploadedByRol: media.uploadedByRol,
    isPrivate: media.isPrivate,
    sharedWithRamas: media.sharedWithRamas,
    originalName: media.originalName,
    mimeType: media.mimeType,
    size: media.size,
    extension: media.extension,
    createdAt: media.createdAt,
    uploadedAt: createdAtDate ? createdAtDate.toISOString() : null,
    url,
    viewUrl,
    downloadUrl,
    uploader: {
      rut: uploaderRut,
      nombreCompleto: uploaderNombre,
      email: uploaderEmail,
      rol: uploaderRol,
      avatarUrl,
      avatarVersion,
    },
  };
}

function formatMediaList(medias, req) {
  return medias.map((item) => buildMediaPayload(item, req));
}

async function ensureUserCanAccessMedia(req, media) {
  const user = req.user;

  if (!user) {
    return {
      ok: false,
      status: 401,
      message: "No autenticado",
      details: "Debes iniciar sesión para acceder a este recurso.",
    };
  }

  if (user.rol === "directiva") {
    return { ok: true };
  }

  if (media.uploadedByRut && media.uploadedByRut === user.rut) {
    return { ok: true };
  }

  if (media.isPrivate) {
    return {
      ok: false,
      status: 403,
      message: "Contenido privado",
      details:
        "Solo la directiva puede descargar elementos de visibilidad privada.",
    };
  }

  if (!media.eventoDeportivoId) {
    return {
      ok: false,
      status: 403,
      message: "No autorizado",
      details:
        "No se pudo validar la pertenencia al evento para este recurso.",
    };
  }

  const participacion = await participacionDeportivaRepository.findOne({
    where: {
      eventoDeportivoId: media.eventoDeportivoId,
      rutRamaExterna: user.rut,
    },
  });

  if (!participacion) {
    return {
      ok: false,
      status: 403,
      message: "No autorizado",
      details:
        "Solo las ramas participantes y la directiva pueden descargar este contenido.",
    };
  }

  return { ok: true };
}

function resolveAbsoluteMediaPath(media) {
  const storagePath = media.storagePath;
  const normalized = storagePath.replace(/\\/g, path.sep);
  return path.resolve("uploads", normalized);
}

export async function subirMultimediaDirectiva(req, res) {
  try {
    const { id: eventoId } = req.params;
    const { visibilidad } = req.body;
    const archivo = req.file;

    if (!archivo) {
      return handleErrorClient(
        res,
        400,
        "Archivo requerido",
        "Debes adjuntar una imagen en formato JPG, PNG, WEBP o GIF.",
      );
    }

    const validacion = await ensureEventoDeportivoFinalizado(eventoId);
    if (!validacion.ok) {
      cleanupUploadedFile(archivo);
      return handleErrorClient(
        res,
        validacion.error.status,
        validacion.error.message,
      );
    }

    const evento = validacion.evento;
    const esPrivado = visibilidad === "privada";

    try {
      await optimizeUploadedImage(archivo, {
        maxWidth: 1600,
        maxHeight: 1600,
        quality: 80,
      });
    } catch (error) {
      cleanupUploadedFile(archivo);
      return handleErrorServer(res, 500, "Error procesando la imagen", error.message);
    }

    const relativeStoragePath = path
      .relative(path.resolve("uploads"), archivo.path)
      .replace(/\\/g, "/");

    const registro = multimediaRepository.create({
      eventoDeportivoId: evento.id,
      tituloEvento: evento.titulo,
      uploadedByRut: req.user.rut,
      uploadedByNombre: req.user.nombreCompleto || null,
      uploadedByRol: req.user.rol,
      fileName: archivo.filename,
      originalName: archivo.originalname,
      mimeType: archivo.mimetype,
      size: archivo.size,
      extension: path.extname(archivo.originalname).replace(".", ""),
      isPrivate: esPrivado,
      sharedWithRamas: !esPrivado,
      storagePath: relativeStoragePath,
    });

    const guardado = await multimediaRepository.save(registro);
    const guardadoConRelaciones = await multimediaRepository.findOne({
      where: { id: guardado.id },
      relations: {
        uploader: true,
      },
    });
    const payload = buildMediaPayload(
      guardadoConRelaciones ?? guardado,
      req,
    );

    handleSuccess(res, 201, "Imagen subida exitosamente", payload);
  } catch (error) {
    cleanupUploadedFile(req.file);
    console.error("Error subiendo multimedia directiva:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function subirMultimediaRama(req, res) {
  try {
    const { id: eventoId } = req.params;
    const archivo = req.file;

    if (!archivo) {
      return handleErrorClient(
        res,
        400,
        "Archivo requerido",
        "Debes adjuntar una imagen en formato JPG, PNG, WEBP o GIF.",
      );
    }

    const validacion = await ensureEventoDeportivoFinalizado(eventoId);
    if (!validacion.ok) {
      cleanupUploadedFile(archivo);
      return handleErrorClient(
        res,
        validacion.error.status,
        validacion.error.message,
      );
    }

    const participacion = await participacionDeportivaRepository.findOne({
      where: {
        eventoDeportivoId: eventoId,
        rutRamaExterna: req.user.rut,
      },
    });

    if (!participacion) {
      cleanupUploadedFile(archivo);
      return handleErrorClient(
        res,
        403,
        "No autorizado",
        "Solo las ramas que participaron en el evento pueden subir imágenes.",
      );
    }

    try {
      await optimizeUploadedImage(archivo, {
        maxWidth: 1600,
        maxHeight: 1600,
        quality: 80,
      });
    } catch (error) {
      cleanupUploadedFile(archivo);
      return handleErrorServer(res, 500, "Error procesando la imagen", error.message);
    }

    const relativeStoragePath = path
      .relative(path.resolve("uploads"), archivo.path)
      .replace(/\\/g, "/");

    const registro = multimediaRepository.create({
      eventoDeportivoId: eventoId,
      tituloEvento: validacion.evento.titulo,
      uploadedByRut: req.user.rut,
      uploadedByNombre: req.user.nombreCompleto || null,
      uploadedByRol: req.user.rol,
      fileName: archivo.filename,
      originalName: archivo.originalname,
      mimeType: archivo.mimetype,
      size: archivo.size,
      extension: path.extname(archivo.originalname).replace(".", ""),
      isPrivate: false,
      sharedWithRamas: true,
      storagePath: relativeStoragePath,
    });

    const guardado = await multimediaRepository.save(registro);
    const guardadoConRelaciones = await multimediaRepository.findOne({
      where: { id: guardado.id },
      relations: {
        uploader: true,
      },
    });
    const payload = buildMediaPayload(
      guardadoConRelaciones ?? guardado,
      req,
    );

    handleSuccess(res, 201, "Imagen subida exitosamente", payload);
  } catch (error) {
    cleanupUploadedFile(req.file);
    console.error("Error subiendo multimedia rama externa:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerMultimediaEventoDirectiva(req, res) {
  try {
    const { id: eventoId } = req.params;
    const { visibilidad } = req.query;

    const qb = multimediaRepository
      .createQueryBuilder("media")
      .leftJoinAndSelect("media.eventoDeportivo", "eventoDeportivo")
      .leftJoinAndSelect("media.evento", "eventoGenerico")
      .leftJoinAndSelect("media.uploader", "uploader")
      .where("media.eventoDeportivoId = :eventoId", { eventoId })
      .orderBy("media.createdAt", "DESC");

    if (visibilidad === "privada") {
      qb.andWhere("media.isPrivate = true");
    } else if (visibilidad === "compartida") {
      qb.andWhere("media.isPrivate = false");
    }

    const registros = await qb.getMany();
    const data = formatMediaList(registros, req);

    handleSuccess(
      res,
      200,
      "Multimedia del evento obtenida exitosamente",
      data,
    );
  } catch (error) {
    console.error("Error obteniendo multimedia para directiva:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerMultimediaEventoCompartido(req, res) {
  try {
    const { id: eventoId } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      const participacion = await participacionDeportivaRepository.findOne({
        where: {
          eventoDeportivoId: eventoId,
          rutRamaExterna: req.user.rut,
        },
      });

      if (!participacion) {
        return handleErrorClient(
          res,
          403,
          "No autorizado",
          "Solo las ramas participantes y la directiva pueden visualizar este contenido.",
        );
      }
    }

    const registros = await multimediaRepository
      .createQueryBuilder("media")
      .leftJoinAndSelect("media.uploader", "uploader")
      .where("media.eventoDeportivoId = :eventoId", { eventoId })
      .andWhere("media.isPrivate = false")
      .orderBy("media.createdAt", "DESC")
      .getMany();

    const data = formatMediaList(registros, req);

    handleSuccess(
      res,
      200,
      "Multimedia compartida obtenida exitosamente",
      data,
    );
  } catch (error) {
    console.error("Error obteniendo multimedia compartida:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerMultimediaGlobalDirectiva(req, res) {
  try {
    const {
      fechaDesde,
      fechaHasta,
      evento,
      rut,
      rol,
      visibilidad,
    } = req.query;

    const qb = multimediaRepository
      .createQueryBuilder("media")
      .leftJoinAndSelect("media.eventoDeportivo", "eventoDeportivo")
      .leftJoinAndSelect("media.evento", "eventoGenerico")
      .leftJoinAndSelect("media.uploader", "uploader")
      .orderBy("media.createdAt", "DESC");

    if (fechaDesde) {
      const inicio = new Date(fechaDesde);
      qb.andWhere("media.createdAt >= :fechaDesde", { fechaDesde: inicio });
    }

    if (fechaHasta) {
      const fin = new Date(fechaHasta);
      qb.andWhere("media.createdAt <= :fechaHasta", { fechaHasta: fin });
    }

    if (evento) {
      const likeQuery = `%${evento.toLowerCase()}%`;
      qb.andWhere("LOWER(media.tituloEvento) LIKE :evento", {
        evento: likeQuery,
      });
    }

    if (rut) {
      qb.andWhere("media.uploadedByRut = :rut", { rut });
    }

    if (rol) {
      qb.andWhere("media.uploadedByRol = :rol", { rol });
    }

    if (visibilidad === "privada") {
      qb.andWhere("media.isPrivate = true");
    } else if (visibilidad === "compartida") {
      qb.andWhere("media.isPrivate = false");
    }

    const registros = await qb.getMany();
    const data = formatMediaList(registros, req);

    handleSuccess(res, 200, "Multimedia obtenida exitosamente", data);
  } catch (error) {
    console.error("Error obteniendo multimedia global:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function descargarMultimediaEvento(req, res) {
  try {
    const { id: eventoId, mediaId } = req.params;

    const media = await multimediaRepository.findOne({
      where: { id: mediaId },
    });

    if (!media) {
      return handleErrorClient(
        res,
        404,
        "Multimedia no encontrada",
        "El recurso solicitado no está disponible.",
      );
    }

    const matchesEventoDeportivo =
      media.eventoDeportivoId &&
      media.eventoDeportivoId.toString() === eventoId;
    const matchesEventoGenerico =
      media.eventoId !== undefined &&
      media.eventoId !== null &&
      String(media.eventoId) === eventoId;

    if (!matchesEventoDeportivo && !matchesEventoGenerico) {
      return handleErrorClient(
        res,
        404,
        "Multimedia no encontrada",
        "El recurso no corresponde al evento indicado.",
      );
    }

    const { ok, status, message, details } = await ensureUserCanAccessMedia(
      req,
      media,
    );
    if (!ok) {
      return handleErrorClient(res, status ?? 403, message, details);
    }

    const absolutePath = resolveAbsoluteMediaPath(media);

    if (!fs.existsSync(absolutePath)) {
      return handleErrorClient(
        res,
        404,
        "Archivo no disponible",
        "El archivo original no se encuentra en el servidor.",
      );
    }

    res.setHeader(
      "Content-Type",
      media.mimeType || "application/octet-stream",
    );
    if (media.size) {
      res.setHeader("Content-Length", media.size);
    }

    return res.download(absolutePath, media.originalName, (downloadError) => {
      if (downloadError) {
        console.error("Error enviando archivo multimedia:", downloadError);
        if (!res.headersSent) {
          handleErrorServer(
            res,
            500,
            "Error descargando archivo multimedia",
            downloadError.message,
          );
        }
      }
    });
  } catch (error) {
    console.error("Error general al descargar multimedia:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function eliminarMultimediaEvento(req, res) {
  try {
    const { id: eventoId, mediaId } = req.params;

    const media = await multimediaRepository.findOne({
      where: { id: mediaId },
    });

    if (!media) {
      return handleErrorClient(
        res,
        404,
        "Multimedia no encontrada",
        "El recurso solicitado no está disponible.",
      );
    }

    const matchesEventoDeportivo =
      media.eventoDeportivoId &&
      media.eventoDeportivoId.toString() === eventoId;
    const matchesEventoGenerico =
      media.eventoId !== undefined &&
      media.eventoId !== null &&
      String(media.eventoId) === eventoId;

    if (!matchesEventoDeportivo && !matchesEventoGenerico) {
      return handleErrorClient(
        res,
        404,
        "Multimedia no encontrada",
        "El recurso no corresponde al evento indicado.",
      );
    }

    // Solo la directiva puede eliminar multimedia
    if (req.user.rol !== "directiva") {
      return handleErrorClient(
        res,
        403,
        "No autorizado",
        "Solo la directiva puede eliminar multimedia.",
      );
    }

    // Eliminar el archivo físico si existe
    const absolutePath = resolveAbsoluteMediaPath(media);
    if (fs.existsSync(absolutePath)) {
      try {
        fs.unlinkSync(absolutePath);
      } catch (fileError) {
        console.error("Error eliminando archivo físico:", fileError);
        // Continuar con la eliminación del registro aunque falle eliminar el archivo
      }
    }

    // Eliminar el registro de la base de datos
    await multimediaRepository.remove(media);

    handleSuccess(
      res,
      200,
      "Multimedia eliminada exitosamente",
      { id: mediaId },
    );
  } catch (error) {
    console.error("Error eliminando multimedia:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
