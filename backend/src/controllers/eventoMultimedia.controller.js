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
import { In } from "typeorm";

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

function buildMediaPayload(media, req) {
  const baseUrl = `${req.protocol}://${req.get("host")}`;
  const normalizedPath = media.storagePath.replace(/\\/g, "/");
  const url = `${baseUrl}/uploads/${normalizedPath}`;

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
    url,
  };
}

async function formatMediaList(medias, req) {
  return Promise.all(
    medias.map(async (item) => buildMediaPayload(item, req)),
  );
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
    const payload = buildMediaPayload(guardado, req);

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
    const payload = buildMediaPayload(guardado, req);

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
      .where("media.eventoDeportivoId = :eventoId", { eventoId })
      .orderBy("media.createdAt", "DESC");

    if (visibilidad === "privada") {
      qb.andWhere("media.isPrivate = true");
    } else if (visibilidad === "compartida") {
      qb.andWhere("media.isPrivate = false");
    }

    const registros = await qb.getMany();
    const data = await formatMediaList(registros, req);

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

    const registros = await multimediaRepository.find({
      where: {
        eventoDeportivoId: eventoId,
        isPrivate: false,
      },
      order: {
        createdAt: "DESC",
      },
    });

    const data = await formatMediaList(registros, req);

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
    const data = await formatMediaList(registros, req);

    handleSuccess(res, 200, "Multimedia obtenida exitosamente", data);
  } catch (error) {
    console.error("Error obteniendo multimedia global:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
