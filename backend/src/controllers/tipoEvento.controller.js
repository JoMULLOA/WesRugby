import { AppDataSource } from "../config/configDb.js";
import TipoEvento from "../entity/tipoEvento.entity.js";
import {
  handleSuccess,
  handleErrorClient,
  handleErrorServer,
} from "../handlers/responseHandlers.js";

const tipoEventoRepository = AppDataSource.getRepository(TipoEvento);

// Obtener todos los tipos de evento activos
const obtenerTiposEvento = async (req, res) => {
  try {
    const tipos = await tipoEventoRepository.find({
      where: { activo: true },
      order: { nombre: "ASC" },
    });

    return handleSuccess(
      res,
      200,
      "Tipos de evento obtenidos exitosamente",
      tipos,
    );
  } catch (err) {
    console.error("Error al obtener tipos de evento:", err);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Obtener todos los tipos de evento (incluyendo inactivos) - Solo para directiva
const obtenerTodosTiposEvento = async (req, res) => {
  try {
    const tipos = await tipoEventoRepository.find({
      order: { nombre: "ASC" },
    });

    return handleSuccess(
      res,
      200,
      "Todos los tipos de evento obtenidos exitosamente",
      tipos,
    );
  } catch (err) {
    console.error("Error al obtener todos los tipos de evento:", err);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Crear un nuevo tipo de evento
const crearTipoEvento = async (req, res) => {
  try {
    const { nombre, esDeportivo } = req.body;

    if (!nombre || typeof esDeportivo !== "boolean") {
      return handleErrorClient(res, 400, "Error de validación", {
        info: "Nombre y esDeportivo son requeridos",
      });
    }

    // Verificar que no exista un tipo con el mismo nombre
    const tipoExistente = await tipoEventoRepository.findOne({
      where: { nombre: nombre.trim() },
    });

    if (tipoExistente) {
      return handleErrorClient(res, 409, "Conflicto", {
        info: "Ya existe un tipo de evento con ese nombre",
      });
    }

    const nuevoTipo = tipoEventoRepository.create({
      nombre: nombre.trim(),
      esDeportivo,
      activo: true,
    });

    const tipoGuardado = await tipoEventoRepository.save(nuevoTipo);

    return handleSuccess(
      res,
      201,
      "Tipo de evento creado exitosamente",
      tipoGuardado,
    );
  } catch (err) {
    console.error("Error al crear tipo de evento:", err);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Actualizar un tipo de evento
const actualizarTipoEvento = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, esDeportivo, activo } = req.body;

    const tipo = await tipoEventoRepository.findOne({
      where: { id },
    });

    if (!tipo) {
      return handleErrorClient(res, 404, "No encontrado", {
        info: "Tipo de evento no encontrado",
      });
    }

    // Verificar nombre duplicado si se está cambiando
    if (nombre && nombre.trim() !== tipo.nombre) {
      const tipoExistente = await tipoEventoRepository.findOne({
        where: { nombre: nombre.trim() },
      });

      if (tipoExistente) {
        return handleErrorClient(res, 409, "Conflicto", {
          info: "Ya existe un tipo de evento con ese nombre",
        });
      }
    }

    // Actualizar campos
    if (nombre) tipo.nombre = nombre.trim();
    if (typeof esDeportivo === "boolean") tipo.esDeportivo = esDeportivo;
    if (typeof activo === "boolean") tipo.activo = activo;

    const tipoActualizado = await tipoEventoRepository.save(tipo);

    return handleSuccess(
      res,
      200,
      "Tipo de evento actualizado exitosamente",
      tipoActualizado,
    );
  } catch (err) {
    console.error("Error al actualizar tipo de evento:", err);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Eliminar (desactivar) un tipo de evento
const eliminarTipoEvento = async (req, res) => {
  try {
    const { id } = req.params;

    const tipo = await tipoEventoRepository.findOne({
      where: { id },
    });

    if (!tipo) {
      return handleErrorClient(res, 404, "No encontrado", {
        info: "Tipo de evento no encontrado",
      });
    }

    // Solo desactivar, no eliminar físicamente
    tipo.activo = false;
    await tipoEventoRepository.save(tipo);

    return handleSuccess(res, 200, "Tipo de evento eliminado exitosamente");
  } catch (err) {
    console.error("Error al eliminar tipo de evento:", err);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Reactivar un tipo de evento
const reactivarTipoEvento = async (req, res) => {
  try {
    const { id } = req.params;

    const tipo = await tipoEventoRepository.findOne({
      where: { id },
    });

    if (!tipo) {
      return handleErrorClient(res, 404, "No encontrado", {
        info: "Tipo de evento no encontrado",
      });
    }

    tipo.activo = true;
    await tipoEventoRepository.save(tipo);

    return handleSuccess(
      res,
      200,
      "Tipo de evento reactivado exitosamente",
      tipo,
    );
  } catch (err) {
    console.error("Error al reactivar tipo de evento:", err);
    return handleErrorServer(res, 500, "Error interno del servidor");
  }
};

export {
  obtenerTiposEvento,
  obtenerTodosTiposEvento,
  crearTipoEvento,
  actualizarTipoEvento,
  eliminarTipoEvento,
  reactivarTipoEvento,
};
