"use strict";
import { AppDataSource } from "../config/configDb.js";
import ConfiguracionPrecio from "../entity/configuracionPrecio.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const configuracionPrecioRepository =
  AppDataSource.getRepository(ConfiguracionPrecio);

/**
 * Obtener la configuración de precios para un año específico
 */
export async function obtenerPreciosPorAnio(req, res) {
  try {
    const { anio } = req.params;
    const anioNum = parseInt(anio, 10);

    if (isNaN(anioNum)) {
      return handleErrorClient(res, 400, "Año inválido");
    }

    const configuracion = await configuracionPrecioRepository.findOne({
      where: { anio: anioNum },
    });

    if (!configuracion) {
      return handleSuccess(
        res,
        200,
        "No hay configuración de precios para este año",
        {
          anio: anioNum,
          precioMensualidad: null,
          precioMatricula: null,
          descuentoMensualidad2: null,
          descuentoMensualidad3Plus: null,
          descuentoMatricula2: null,
          descuentoMatricula3Plus: null,
        },
      );
    }

    handleSuccess(res, 200, "Configuración de precios obtenida", {
      id: configuracion.id,
      anio: configuracion.anio,
      precioMensualidad: parseFloat(configuracion.precioMensualidad),
      precioMatricula: parseFloat(configuracion.precioMatricula),
      descuentoMensualidad2: configuracion.descuentoMensualidad2,
      descuentoMensualidad3Plus: configuracion.descuentoMensualidad3Plus,
      descuentoMatricula2: configuracion.descuentoMatricula2,
      descuentoMatricula3Plus: configuracion.descuentoMatricula3Plus,
      fechaCreacion: configuracion.fechaCreacion,
      fechaActualizacion: configuracion.fechaActualizacion,
    });
  } catch (error) {
    console.error("Error al obtener configuración de precios:", error);
    handleErrorServer(res, 500, "Error al obtener configuración de precios");
  }
}

/**
 * Crear o actualizar la configuración de precios para un año
 */
export async function guardarPrecios(req, res) {
  try {
    const {
      anio,
      precioMensualidad,
      precioMatricula,
      descuentoMensualidad2,
      descuentoMensualidad3Plus,
      descuentoMatricula2,
      descuentoMatricula3Plus,
    } = req.body;

    // Validaciones
    if (!anio || !precioMensualidad || !precioMatricula) {
      return handleErrorClient(
        res,
        400,
        "Faltan campos requeridos: anio, precioMensualidad, precioMatricula",
      );
    }

    const anioNum = parseInt(anio, 10);
    const mensualidadNum = parseFloat(precioMensualidad);
    const matriculaNum = parseFloat(precioMatricula);
    const descMen2 =
      descuentoMensualidad2 !== undefined
        ? parseInt(descuentoMensualidad2, 10)
        : 0;
    const descMen3 =
      descuentoMensualidad3Plus !== undefined
        ? parseInt(descuentoMensualidad3Plus, 10)
        : 0;
    const descMat2 =
      descuentoMatricula2 !== undefined ? parseInt(descuentoMatricula2, 10) : 0;
    const descMat3 =
      descuentoMatricula3Plus !== undefined
        ? parseInt(descuentoMatricula3Plus, 10)
        : 0;

    if (isNaN(anioNum) || anioNum < 2020 || anioNum > 2100) {
      return handleErrorClient(res, 400, "Año inválido");
    }

    if (isNaN(mensualidadNum) || mensualidadNum <= 0) {
      return handleErrorClient(res, 400, "Precio de mensualidad inválido");
    }

    if (isNaN(matriculaNum) || matriculaNum <= 0) {
      return handleErrorClient(res, 400, "Precio de matrícula inválido");
    }

    // Validar porcentajes de descuento (enteros 0-100)
    const descuentos = [descMen2, descMen3, descMat2, descMat3];
    for (const d of descuentos) {
      if (isNaN(d) || d < 0 || d > 100) {
        return handleErrorClient(
          res,
          400,
          "Los descuentos deben ser enteros entre 0 y 100",
        );
      }
    }

    // Buscar si ya existe configuración para este año
    let configuracion = await configuracionPrecioRepository.findOne({
      where: { anio: anioNum },
    });

    if (configuracion) {
      // Actualizar
      configuracion.precioMensualidad = mensualidadNum;
      configuracion.descuentoMensualidad2 = descMen2;
      configuracion.descuentoMensualidad3Plus = descMen3;
      configuracion.precioMatricula = matriculaNum;
      configuracion.descuentoMatricula2 = descMat2;
      configuracion.descuentoMatricula3Plus = descMat3;
      await configuracionPrecioRepository.save(configuracion);

      console.log(
        `✅ Configuración de precios actualizada para año ${anioNum}`,
      );

      return handleSuccess(res, 200, "Configuración de precios actualizada", {
        id: configuracion.id,
        anio: configuracion.anio,
        precioMensualidad: parseFloat(configuracion.precioMensualidad),
        precioMatricula: parseFloat(configuracion.precioMatricula),
        descuentoMensualidad2: configuracion.descuentoMensualidad2,
        descuentoMensualidad3Plus: configuracion.descuentoMensualidad3Plus,
        descuentoMatricula2: configuracion.descuentoMatricula2,
        descuentoMatricula3Plus: configuracion.descuentoMatricula3Plus,
      });
    } else {
      // Crear nueva
      configuracion = configuracionPrecioRepository.create({
        anio: anioNum,
        precioMensualidad: mensualidadNum,
        descuentoMensualidad2: descMen2,
        descuentoMensualidad3Plus: descMen3,
        precioMatricula: matriculaNum,
        descuentoMatricula2: descMat2,
        descuentoMatricula3Plus: descMat3,
      });

      await configuracionPrecioRepository.save(configuracion);

      console.log(`✅ Configuración de precios creada para año ${anioNum}`);

      return handleSuccess(res, 201, "Configuración de precios creada", {
        id: configuracion.id,
        anio: configuracion.anio,
        precioMensualidad: parseFloat(configuracion.precioMensualidad),
        precioMatricula: parseFloat(configuracion.precioMatricula),
        descuentoMensualidad2: configuracion.descuentoMensualidad2,
        descuentoMensualidad3Plus: configuracion.descuentoMensualidad3Plus,
        descuentoMatricula2: configuracion.descuentoMatricula2,
        descuentoMatricula3Plus: configuracion.descuentoMatricula3Plus,
      });
    }
  } catch (error) {
    console.error("Error al guardar configuración de precios:", error);
    handleErrorServer(res, 500, "Error al guardar configuración de precios");
  }
}

/**
 * Obtener todas las configuraciones de precios
 */
export async function obtenerTodasLasConfiguraciones(req, res) {
  try {
    const configuraciones = await configuracionPrecioRepository.find({
      order: { anio: "DESC" },
    });

    const configuracionesFormateadas = configuraciones.map((config) => ({
      id: config.id,
      anio: config.anio,
      precioMensualidad: parseFloat(config.precioMensualidad),
      descuentoMensualidad2: config.descuentoMensualidad2,
      descuentoMensualidad3Plus: config.descuentoMensualidad3Plus,
      precioMatricula: parseFloat(config.precioMatricula),
      descuentoMatricula2: config.descuentoMatricula2,
      descuentoMatricula3Plus: config.descuentoMatricula3Plus,
      fechaCreacion: config.fechaCreacion,
      fechaActualizacion: config.fechaActualizacion,
    }));

    handleSuccess(
      res,
      200,
      "Configuraciones de precios obtenidas",
      configuracionesFormateadas,
    );
  } catch (error) {
    console.error("Error al obtener configuraciones:", error);
    handleErrorServer(res, 500, "Error al obtener configuraciones de precios");
  }
}
