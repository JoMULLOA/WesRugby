"use strict";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

/**
 * Obtener estadísticas generales del sistema
 */
export async function obtenerEstadisticasGenerales(req, res) {
  try {
    // Estadísticas básicas sin viajes
    const estadisticas = {
      totalUsuarios: 0,
      usuariosActivos: 0,
      totalVehiculos: 0,
      totalAmistades: 0,
      totalNotificaciones: 0,
      totalTransacciones: 0,
    };

    return handleSuccess(res, 200, "Estadísticas obtenidas exitosamente", estadisticas);
  } catch (error) {
    console.error("Error al obtener estadísticas generales:", error.message);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
}

/**
 * Obtener distribución de puntuaciones (placeholder)
 */
export async function obtenerDistribucionPuntuaciones(req, res) {
  try {
    const distribucion = {
      excelente: 0,
      bueno: 0,
      regular: 0,
      malo: 0,
    };

    return handleSuccess(res, 200, "Distribución de puntuaciones obtenida", distribucion);
  } catch (error) {
    console.error("Error al obtener distribución:", error.message);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
}

/**
 * Obtener viajes por mes (placeholder - funcionalidad eliminada)
 */
export async function obtenerViajesPorMes(req, res) {
  try {
    return handleErrorClient(res, 404, "Funcionalidad de viajes eliminada");
  } catch (error) {
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
}

/**
 * Obtener clasificación de usuarios (placeholder)
 */
export async function obtenerClasificacionUsuarios(req, res) {
  try {
    const clasificacion = [];
    return handleSuccess(res, 200, "Clasificación obtenida", clasificacion);
  } catch (error) {
    console.error("Error al obtener clasificación:", error.message);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
}

/**
 * Obtener destinos populares (placeholder - funcionalidad eliminada)
 */
export async function obtenerDestinosPopulares(req, res) {
  try {
    return handleErrorClient(res, 404, "Funcionalidad de viajes eliminada");
  } catch (error) {
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
}

/**
 * Obtener análisis avanzado (placeholder)
 */
export async function obtenerAnalisisAvanzado(req, res) {
  try {
    const analisis = {
      tendencias: [],
      predicciones: [],
      insights: [],
    };

    return handleSuccess(res, 200, "Análisis avanzado obtenido", analisis);
  } catch (error) {
    console.error("Error al obtener análisis avanzado:", error.message);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
}
