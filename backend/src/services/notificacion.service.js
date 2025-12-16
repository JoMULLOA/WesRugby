import { AppDataSource } from "../config/configDb.js";
import Notificacion from "../entity/notificacion.entity.js";
import User from "../entity/user.entity.js";

const notificacionRepository = AppDataSource.getRepository(Notificacion);
const userRepository = AppDataSource.getRepository(User);

/**
 * Crear una notificación
 * @param {Object} notificacionData - Datos de la notificación
 * @returns {Promise<Object>} Notificación creada
 */
export async function crearNotificacionService(notificacionData) {
  try {
    const { tipo, titulo, mensaje, rutReceptor, rutEmisor, datos } = notificacionData;

    // Verificar que el receptor existe
    const receptor = await userRepository.findOne({ where: { rut: rutReceptor } });
    if (!receptor) {
      throw new Error("Receptor no encontrado");
    }

    const notificacion = notificacionRepository.create({
      tipo,
      titulo,
      mensaje,
      rutReceptor,
      rutEmisor,
      datos,
      leida: false,
      fechaCreacion: new Date(),
    });

    const notificacionGuardada = await notificacionRepository.save(notificacion);

    return {
      success: true,
      data: notificacionGuardada,
      message: "Notificación creada exitosamente",
    };

  } catch (error) {
    console.error("Error al crear notificación:", error.message);
    throw new Error(`Error al crear notificación: ${error.message}`);
  }
}

/**
 * Crear notificaciones masivas
 * @param {Object} params - Parámetros
 * @param {Array} params.destinatarios - Lista de RUTs de destinatarios
 * @param {string} params.titulo - Título de la notificación
 * @param {string} params.mensaje - Mensaje de la notificación
 * @param {string} params.tipo - Tipo de notificación
 * @param {Object} params.datos - Datos adicionales
 * @param {string} params.rutEmisor - RUT del emisor
 * @returns {Promise<Array>} Resultado
 */
export async function crearNotificacionMasivaService({ destinatarios, titulo, mensaje, tipo, datos, rutEmisor }) {
  try {
    const notificaciones = destinatarios.map(rutReceptor => ({
      tipo,
      titulo,
      mensaje,
      rutReceptor,
      rutEmisor,
      datos,
      leida: false,
      fechaCreacion: new Date(),
    }));

    // Validar que existan los usuarios (opcional, por rendimiento se puede omitir o hacer en lote)
    // Por ahora asumimos que los RUTs vienen validados desde el frontend/controlador anterior

    const resultado = await notificacionRepository.save(notificaciones);

    return [{
      success: true,
      count: resultado.length,
      message: `${resultado.length} notificaciones creadas`
    }, null];

  } catch (error) {
    console.error("Error al crear notificaciones masivas:", error.message);
    return [null, `Error al crear notificaciones: ${error.message}`];
  }
}

/**
 * Obtener notificaciones de un usuario
 * @param {string} rutUsuario - RUT del usuario
 * @param {number} limite - Límite de notificaciones a obtener
 * @returns {Promise<Array>} Lista de notificaciones
 */
export async function obtenerNotificacionesUsuario(rutUsuario, limite = 50) {
  try {
    const notificaciones = await notificacionRepository.find({
      where: { rutReceptor: rutUsuario },
      order: { fechaCreacion: "DESC" },
      take: limite,
    });

    return {
      success: true,
      data: notificaciones,
    };

  } catch (error) {
    console.error("Error al obtener notificaciones:", error.message);
    throw new Error(`Error al obtener notificaciones: ${error.message}`);
  }
}

/**
 * Eliminar una notificación
 * @param {number} idNotificacion - ID de la notificación
 * @param {string} rutUsuario - RUT del usuario
 * @returns {Promise<Object>} Resultado de la operación
 */
export async function eliminarNotificacion(idNotificacion, rutUsuario) {
  try {
    console.log(`[DEBUG] Intentando eliminar notificación. ID: ${idNotificacion}, RUT Usuario: ${rutUsuario}`);

    // Verificar si existe primero para debug
    const notificacion = await notificacionRepository.findOne({ where: { id: parseInt(idNotificacion) } });
    if (!notificacion) {
      console.log(`[DEBUG] Notificación ${idNotificacion} no encontrada en DB.`);
    } else {
      console.log(`[DEBUG] Notificación encontrada:`, notificacion);
      if (notificacion.rutReceptor !== rutUsuario) {
        console.log(`[DEBUG] Mismatch de RUT. Receptor en DB: ${notificacion.rutReceptor}, Usuario solicitante: ${rutUsuario}`);
      }
    }

    const resultado = await notificacionRepository.delete({
      id: parseInt(idNotificacion),
      rutReceptor: rutUsuario,
    });

    console.log(`[DEBUG] Resultado delete:`, resultado);

    if (resultado.affected === 0) {
      throw new Error("Notificación no encontrada o no tienes permisos");
    }

    return {
      success: true,
      message: "Notificación eliminada correctamente",
    };

  } catch (error) {
    console.error("Error al eliminar notificación:", error.message);
    throw new Error(`Error al eliminar notificación: ${error.message}`);
  }
}

/**
 * Obtener notificaciones de un usuario (alias para compatibilidad)
 * @param {string} rutUsuario - RUT del usuario
 * @param {number} limite - Límite de notificaciones a obtener
 * @returns {Promise<Array>} Lista de notificaciones
 */
export async function obtenerNotificacionesService(rutUsuario, limite = 50) {
  return await obtenerNotificacionesUsuario(rutUsuario, limite);
}

/**
 * Contar notificaciones pendientes (no leídas)
 * @param {string} rutUsuario - RUT del usuario
 * @returns {Promise<Object>} Número de notificaciones pendientes
 */
export async function contarNotificacionesPendientesService(rutUsuario) {
  try {
    const count = await notificacionRepository.count({
      where: { rutReceptor: rutUsuario, leida: false },
    });

    return {
      success: true,
      data: { count },
    };

  } catch (error) {
    console.error("Error al contar notificaciones pendientes:", error.message);
    throw new Error(`Error al contar notificaciones pendientes: ${error.message}`);
  }
}

/**
 * Marcar notificación como leída (alias para compatibilidad)
 * @param {number} idNotificacion - ID de la notificación
 * @param {string} rutUsuario - RUT del usuario
 * @returns {Promise<Object>} Resultado de la operación
 */
export async function marcarComoLeidaService(idNotificacion, rutUsuario) {
  try {
    const resultado = await notificacionRepository.update(
      { id: idNotificacion, rutReceptor: rutUsuario },
      { leida: true }
    );
    return { success: true, message: "Notificación marcada como leída" };
  } catch (error) {
    throw error;
  }
}

/**
 * Función placeholder para compatibilidad - no se usa más
 */
export async function responderSolicitudViajeService() {
  throw new Error("Función no disponible - funcionalidad de viajes eliminada");
}

/**
 * Función placeholder para compatibilidad - no se usa más
 */
export async function manejarAbandonoViaje() {
  throw new Error("Función no disponible - funcionalidad de viajes eliminada");
}