"use strict";
import {
  obtenerNotificacionesService,
  contarNotificacionesPendientesService,
  marcarComoLeidaService,
  crearNotificacionMasivaService,
  eliminarNotificacion as eliminarNotificacionService
} from "../services/notificacion.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function obtenerNotificaciones(req, res) {
  try {
    const rutUsuario = req.user.rut;

    const result = await obtenerNotificacionesService(rutUsuario);

    handleSuccess(res, 200, "Notificaciones obtenidas correctamente", result.data);
  } catch (error) {
    console.error("Error en obtenerNotificaciones:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function contarNotificacionesPendientes(req, res) {
  try {
    const rutUsuario = req.user.rut;

    const result = await contarNotificacionesPendientesService(rutUsuario);

    handleSuccess(res, 200, "Conteo de notificaciones obtenido correctamente", result.data);
  } catch (error) {
    console.error("Error en contarNotificacionesPendientes:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function eliminarNotificacion(req, res) {
  try {
    const { id } = req.params;
    const rutUsuario = req.user.rut;

    const result = await eliminarNotificacionService(id, rutUsuario);

    handleSuccess(res, 200, "Notificación eliminada correctamente", result);
  } catch (error) {
    console.error("Error en eliminarNotificacion:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function crearNotificacionMasiva(req, res) {
  try {
    const { destinatarios, titulo, mensaje, tipo, datos } = req.body;
    const rutEmisor = req.user.rut;

    if (!destinatarios || !Array.isArray(destinatarios) || destinatarios.length === 0) {
      return handleErrorClient(res, 400, "Se requiere una lista de destinatarios");
    }

    const [resultado, error] = await crearNotificacionMasivaService({
      destinatarios,
      titulo,
      mensaje,
      tipo,
      datos,
      rutEmisor
    });

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 201, "Notificaciones enviadas correctamente", resultado);
  } catch (error) {
    console.error("Error en crearNotificacionMasiva:", error);
    handleErrorServer(res, 500, error.message);
  }
}
