"use strict";
import ActaReunion from "../entity/actaReunion.entity.js";
import { AppDataSource } from "../config/configDb.js";

export async function createActaReunionService(actaData) {
  try {
    const actaRepository = AppDataSource.getRepository(ActaReunion);

    // Crear nueva acta de reunión
    const newActa = actaRepository.create(actaData);
    const savedActa = await actaRepository.save(newActa);

    return [savedActa, null];
  } catch (error) {
    console.error("Error crear acta de reunión:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getActasReunionService(filters = {}) {
  try {
    const actaRepository = AppDataSource.getRepository(ActaReunion);
    
    const queryBuilder = actaRepository.createQueryBuilder("acta");

    // Filtros opcionales
    if (filters.estado) {
      queryBuilder.andWhere("acta.estado = :estado", { estado: filters.estado });
    }

    if (filters.fechaDesde) {
      queryBuilder.andWhere("acta.fecha >= :fechaDesde", { fechaDesde: filters.fechaDesde });
    }

    if (filters.fechaHasta) {
      queryBuilder.andWhere("acta.fecha <= :fechaHasta", { fechaHasta: filters.fechaHasta });
    }

    // Ordenar por fecha descendente (más recientes primero)
    queryBuilder.orderBy("acta.fecha", "DESC").addOrderBy("acta.createdAt", "DESC");

    const actas = await queryBuilder.getMany();

    return [actas, null];
  } catch (error) {
    console.error("Error obtener actas de reunión:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getActaReunionService(id) {
  try {
    const actaRepository = AppDataSource.getRepository(ActaReunion);

    const acta = await actaRepository.findOne({
      where: { id }
    });

    if (!acta) {
      return [null, "Acta de reunión no encontrada"];
    }

    return [acta, null];
  } catch (error) {
    console.error("Error obtener acta de reunión:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateActaReunionService(id, updateData) {
  try {
    const actaRepository = AppDataSource.getRepository(ActaReunion);

    const acta = await actaRepository.findOne({
      where: { id }
    });

    if (!acta) {
      return [null, "Acta de reunión no encontrada"];
    }

    // Actualizar campos
    Object.assign(acta, updateData);
    acta.updatedAt = new Date();

    const updatedActa = await actaRepository.save(acta);

    return [updatedActa, null];
  } catch (error) {
    console.error("Error actualizar acta de reunión:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function deleteActaReunionService(id) {
  try {
    const actaRepository = AppDataSource.getRepository(ActaReunion);

    const acta = await actaRepository.findOne({
      where: { id }
    });

    if (!acta) {
      return [null, "Acta de reunión no encontrada"];
    }

    await actaRepository.remove(acta);

    return [{ message: "Acta de reunión eliminada exitosamente" }, null];
  } catch (error) {
    console.error("Error eliminar acta de reunión:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function changeEstadoActaService(id, nuevoEstado) {
  try {
    const actaRepository = AppDataSource.getRepository(ActaReunion);

    const acta = await actaRepository.findOne({
      where: { id }
    });

    if (!acta) {
      return [null, "Acta de reunión no encontrada"];
    }

    // Validar estados permitidos
    const estadosPermitidos = ["borrador", "publicada", "archivada"];
    if (!estadosPermitidos.includes(nuevoEstado)) {
      return [null, "Estado no válido"];
    }

    acta.estado = nuevoEstado;
    acta.updatedAt = new Date();

    const updatedActa = await actaRepository.save(acta);

    return [updatedActa, null];
  } catch (error) {
    console.error("Error cambiar estado del acta:", error);
    return [null, "Error interno del servidor"];
  }
}