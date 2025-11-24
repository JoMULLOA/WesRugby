import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const terminosRepository = AppDataSource.getRepository("TerminosCondiciones");
const aceptacionesRepository = AppDataSource.getRepository("AceptacionesTerminos");

/**
 * Obtener la versión activa de términos y condiciones
 * GET /api/terminos/activo
 * Público (para apoderados)
 */
export async function obtenerTerminosActivos(req, res) {
  try {
    const terminoActivo = await terminosRepository.findOne({
      where: { activo: true },
      order: { fechaActivacion: "DESC" },
    });

    if (!terminoActivo) {
      return handleSuccess(res, 200, "No hay términos activos", null);
    }

    handleSuccess(res, 200, "Términos activos obtenidos", {
      id: terminoActivo.id,
      version: terminoActivo.version,
      titulo: terminoActivo.titulo,
      contenido: terminoActivo.contenido,
      fechaActivacion: terminoActivo.fechaActivacion,
    });
  } catch (error) {
    console.error("Error obteniendo términos activos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Verificar si un apoderado ha aceptado los términos activos
 * GET /api/terminos/verificar-aceptacion
 * Requiere autenticación como apoderado
 */
export async function verificarAceptacion(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const userRol = req.user.rol;

    console.log(`🔍 Verificando aceptación - RUT: ${apoderadoRut}, Rol: ${userRol}`);

    // Solo los apoderados deben aceptar términos
    // Directiva, tesorera y entrenador están exentos
    if (userRol !== 'apoderado') {
      console.log(`✅ Usuario con rol "${userRol}" exento de términos`);
      return handleSuccess(res, 200, "Usuario exento de aceptar términos", {
        requiereAceptacion: false,
        terminoActivo: null,
        esApoderado: false,
      });
    }

    // Obtener término activo
    const terminoActivo = await terminosRepository.findOne({
      where: { activo: true },
      order: { fechaActivacion: "DESC" },
    });

    if (!terminoActivo) {
      return handleSuccess(res, 200, "No hay términos que aceptar", {
        requiereAceptacion: false,
        terminoActivo: null,
      });
    }

    // Verificar si ya aceptó esta versión
    const aceptacion = await aceptacionesRepository.findOne({
      where: {
        apoderadoRut,
        terminoId: terminoActivo.id,
      },
    });

    if (aceptacion) {
      return handleSuccess(res, 200, "Términos ya aceptados", {
        requiereAceptacion: false,
        terminoActivo: null,
        fechaAceptacion: aceptacion.fechaAceptacion,
      });
    }

    // Requiere aceptación
    handleSuccess(res, 200, "Requiere aceptación de términos", {
      requiereAceptacion: true,
      terminoActivo: {
        id: terminoActivo.id,
        version: terminoActivo.version,
        titulo: terminoActivo.titulo,
        contenido: terminoActivo.contenido,
        fechaActivacion: terminoActivo.fechaActivacion,
      },
    });
  } catch (error) {
    console.error("Error verificando aceptación:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Registrar aceptación de términos por un apoderado
 * POST /api/terminos/aceptar
 * Requiere autenticación como apoderado
 * Body: { terminoId: number }
 */
export async function aceptarTerminos(req, res) {
  try {
    console.log("📥 Solicitud de aceptación de términos");
    console.log("👤 Usuario:", req.user);
    console.log("📦 Body:", req.body);
    
    const apoderadoRut = req.user.rut;
    const userRol = req.user.rol;
    const { terminoId } = req.body;

    // Solo apoderados pueden aceptar términos
    if (userRol !== 'apoderado') {
      console.log(`❌ Usuario con rol "${userRol}" no puede aceptar términos`);
      return handleErrorClient(res, 403, "Solo los apoderados deben aceptar términos y condiciones");
    }

    if (!terminoId) {
      console.log("❌ Error: terminoId no proporcionado");
      return handleErrorClient(res, 400, "Debe especificar el ID del término");
    }

    console.log(`🔍 Buscando término ID ${terminoId}`);
    
    // Verificar que el término existe y está activo
    const termino = await terminosRepository.findOne({
      where: { id: terminoId, activo: true },
    });

    if (!termino) {
      console.log("❌ Término no encontrado o no activo");
      return handleErrorClient(res, 404, "Término no encontrado o no activo");
    }

    console.log(`✅ Término encontrado: ${termino.version}`);

    // Verificar si ya fue aceptado
    const aceptacionExistente = await aceptacionesRepository.findOne({
      where: {
        apoderadoRut,
        terminoId,
      },
    });

    if (aceptacionExistente) {
      console.log("ℹ️ Ya había aceptado estos términos");
      return handleSuccess(res, 200, "Ya había aceptado estos términos", {
        fechaAceptacion: aceptacionExistente.fechaAceptacion,
      });
    }

    // Obtener IP y User Agent
    const ipAddress = req.ip || req.connection.remoteAddress || "unknown";
    const userAgent = req.headers["user-agent"] || "unknown";

    console.log(`💾 Registrando aceptación para ${apoderadoRut}`);
    
    // Registrar aceptación
    const aceptacion = aceptacionesRepository.create({
      apoderadoRut,
      terminoId,
      version: termino.version,
      ipAddress,
      userAgent,
      fechaAceptacion: new Date(),
    });

    await aceptacionesRepository.save(aceptacion);

    console.log(`✅ Apoderado ${apoderadoRut} aceptó términos v${termino.version}`);

    handleSuccess(res, 201, "Términos aceptados exitosamente", {
      fechaAceptacion: aceptacion.fechaAceptacion,
      version: termino.version,
    });
  } catch (error) {
    console.error("Error aceptando términos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Listar todos los términos (histórico)
 * GET /api/terminos
 * Requiere rol directiva
 */
export async function listarTerminos(req, res) {
  try {
    if (req.user.rol !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const terminos = await terminosRepository.find({
      order: { fechaCreacion: "DESC" },
    });

    handleSuccess(res, 200, "Términos obtenidos", terminos);
  } catch (error) {
    console.error("Error listando términos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Crear nueva versión de términos
 * POST /api/terminos
 * Requiere rol directiva
 * Body: { version: string, titulo: string, contenido: string, activarInmediatamente: boolean }
 */
export async function crearTerminos(req, res) {
  try {
    if (req.user.rol !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { version, titulo, contenido, activarInmediatamente } = req.body;

    if (!version || !titulo || !contenido) {
      return handleErrorClient(
        res,
        400,
        "Debe proporcionar version, titulo y contenido"
      );
    }

    // Si se activa inmediatamente, desactivar todos los demás
    if (activarInmediatamente) {
      await terminosRepository.update({ activo: true }, { activo: false });
    }

    const termino = terminosRepository.create({
      version,
      titulo,
      contenido,
      activo: activarInmediatamente === true,
      creadoPorRut: req.user.rut,
      fechaActivacion: activarInmediatamente ? new Date() : null,
    });

    const guardado = await terminosRepository.save(termino);

    console.log(
      `✅ Términos v${version} creados por ${req.user.rut}${activarInmediatamente ? " (ACTIVO)" : ""}`
    );

    handleSuccess(res, 201, "Términos creados exitosamente", guardado);
  } catch (error) {
    console.error("Error creando términos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Actualizar términos existentes
 * PUT /api/terminos/:id
 * Requiere rol directiva
 * Body: { version?, titulo?, contenido?, activo? }
 */
export async function actualizarTerminos(req, res) {
  try {
    if (req.user.rol !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { id } = req.params;
    const { version, titulo, contenido, activo } = req.body;

    const termino = await terminosRepository.findOne({ where: { id: parseInt(id) } });

    if (!termino) {
      return handleErrorClient(res, 404, "Término no encontrado");
    }

    // Si se activa, desactivar todos los demás
    if (activo === true && !termino.activo) {
      await terminosRepository.update({ activo: true }, { activo: false });
      termino.fechaActivacion = new Date();
    }

    if (version) termino.version = version;
    if (titulo) termino.titulo = titulo;
    if (contenido) termino.contenido = contenido;
    if (typeof activo === "boolean") termino.activo = activo;

    const actualizado = await terminosRepository.save(termino);

    console.log(`✅ Términos ID ${id} actualizados por ${req.user.rut}`);

    handleSuccess(res, 200, "Términos actualizados exitosamente", actualizado);
  } catch (error) {
    console.error("Error actualizando términos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Eliminar términos
 * DELETE /api/terminos/:id
 * Requiere rol directiva
 */
export async function eliminarTerminos(req, res) {
  try {
    if (req.user.rol !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { id } = req.params;

    const termino = await terminosRepository.findOne({ where: { id: parseInt(id) } });

    if (!termino) {
      return handleErrorClient(res, 404, "Término no encontrado");
    }

    if (termino.activo) {
      return handleErrorClient(
        res,
        400,
        "No se puede eliminar un término activo. Desactívelo primero."
      );
    }

    await terminosRepository.remove(termino);

    console.log(`✅ Términos ID ${id} eliminados por ${req.user.rut}`);

    handleSuccess(res, 200, "Términos eliminados exitosamente");
  } catch (error) {
    console.error("Error eliminando términos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Obtener estadísticas de aceptación
 * GET /api/terminos/:id/estadisticas
 * Requiere rol directiva
 */
export async function obtenerEstadisticasAceptacion(req, res) {
  try {
    if (req.user.rol !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { id } = req.params;

    const termino = await terminosRepository.findOne({ where: { id: parseInt(id) } });

    if (!termino) {
      return handleErrorClient(res, 404, "Término no encontrado");
    }

    const aceptaciones = await aceptacionesRepository.find({
      where: { terminoId: parseInt(id) },
      order: { fechaAceptacion: "DESC" },
    });

    const totalAceptaciones = aceptaciones.length;
    const ultimaAceptacion = aceptaciones[0]?.fechaAceptacion || null;

    handleSuccess(res, 200, "Estadísticas obtenidas", {
      terminoId: parseInt(id),
      version: termino.version,
      titulo: termino.titulo,
      activo: termino.activo,
      totalAceptaciones,
      ultimaAceptacion,
      aceptaciones: aceptaciones.map((a) => ({
        apoderadoRut: a.apoderadoRut,
        fechaAceptacion: a.fechaAceptacion,
        ipAddress: a.ipAddress,
      })),
    });
  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
