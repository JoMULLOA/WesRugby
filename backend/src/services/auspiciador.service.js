"use strict";
import Auspiciador from "../entity/auspiciador.entity.js";
import { AppDataSource } from "../config/configDb.js";

export async function createAuspiciadorService(auspiciadorData) {
  try {
    const auspiciadorRepository = AppDataSource.getRepository(Auspiciador);

    // Crear nuevo auspiciador
    const newAuspiciador = auspiciadorRepository.create(auspiciadorData);
    const savedAuspiciador = await auspiciadorRepository.save(newAuspiciador);

    return [savedAuspiciador, null];
  } catch (error) {
    console.error("Error crear auspiciador:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getAuspiciadoresService(filters = {}) {
  try {
    const auspiciadorRepository = AppDataSource.getRepository(Auspiciador);
    
    const queryBuilder = auspiciadorRepository.createQueryBuilder("auspiciador");

    // Filtros opcionales
    if (filters.estado) {
      queryBuilder.andWhere("auspiciador.estado = :estado", { estado: filters.estado });
    }

    // Ordenar por orden y fecha de creación
    queryBuilder.orderBy("auspiciador.orden", "ASC")
                .addOrderBy("auspiciador.createdAt", "DESC");

    const auspiciadores = await queryBuilder.getMany();

    return [auspiciadores, null];
  } catch (error) {
    console.error("Error obtener auspiciadores:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getAuspiciadorService(id) {
  try {
    const auspiciadorRepository = AppDataSource.getRepository(Auspiciador);

    const auspiciador = await auspiciadorRepository.findOne({
      where: { id }
    });

    if (!auspiciador) {
      return [null, "Auspiciador no encontrado"];
    }

    return [auspiciador, null];
  } catch (error) {
    console.error("Error obtener auspiciador:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateAuspiciadorService(id, updateData) {
  try {
    const auspiciadorRepository = AppDataSource.getRepository(Auspiciador);

    const auspiciador = await auspiciadorRepository.findOne({
      where: { id }
    });

    if (!auspiciador) {
      return [null, "Auspiciador no encontrado"];
    }

    // Actualizar campos
    Object.assign(auspiciador, updateData);
    auspiciador.updatedAt = new Date();

    const updatedAuspiciador = await auspiciadorRepository.save(auspiciador);

    return [updatedAuspiciador, null];
  } catch (error) {
    console.error("Error actualizar auspiciador:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function deleteAuspiciadorService(id) {
  try {
    const auspiciadorRepository = AppDataSource.getRepository(Auspiciador);

    const auspiciador = await auspiciadorRepository.findOne({
      where: { id }
    });

    if (!auspiciador) {
      return [null, "Auspiciador no encontrado"];
    }

    await auspiciadorRepository.remove(auspiciador);

    return [{ message: "Auspiciador eliminado exitosamente" }, null];
  } catch (error) {
    console.error("Error eliminar auspiciador:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function changeEstadoAuspiciadorService(id, nuevoEstado) {
  try {
    const auspiciadorRepository = AppDataSource.getRepository(Auspiciador);

    const auspiciador = await auspiciadorRepository.findOne({
      where: { id }
    });

    if (!auspiciador) {
      return [null, "Auspiciador no encontrado"];
    }

    // Validar estados permitidos
    const estadosPermitidos = ["activo", "inactivo"];
    if (!estadosPermitidos.includes(nuevoEstado)) {
      return [null, "Estado no válido"];
    }

    auspiciador.estado = nuevoEstado;
    auspiciador.updatedAt = new Date();

    const updatedAuspiciador = await auspiciadorRepository.save(auspiciador);

    return [updatedAuspiciador, null];
  } catch (error) {
    console.error("Error cambiar estado del auspiciador:", error);
    return [null, "Error interno del servidor"];
  }
}