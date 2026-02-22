"use strict";
import Merchandising from "../entity/merchandising.entity.js";
import { AppDataSource } from "../config/configDb.js";

export async function createMerchandisingService(merchandisingData) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    // Crear nuevo producto
    const newMerchandising = merchandisingRepository.create(merchandisingData);
    const savedMerchandising =
      await merchandisingRepository.save(newMerchandising);

    return [savedMerchandising, null];
  } catch (error) {
    console.error("Error crear merchandising:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getMerchandisingService(filters = {}) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    const queryBuilder =
      merchandisingRepository.createQueryBuilder("merchandising");

    // Filtros opcionales
    if (filters.estado) {
      queryBuilder.andWhere("merchandising.estado = :estado", {
        estado: filters.estado,
      });
    }

    if (filters.disponible !== undefined) {
      queryBuilder.andWhere("merchandising.disponible = :disponible", {
        disponible: filters.disponible,
      });
    }

    if (filters.categoria) {
      queryBuilder.andWhere("merchandising.categoria = :categoria", {
        categoria: filters.categoria,
      });
    }

    // Ordenar por orden y fecha de creación
    queryBuilder
      .orderBy("merchandising.orden", "ASC")
      .addOrderBy("merchandising.createdAt", "DESC");

    const merchandising = await queryBuilder.getMany();

    return [merchandising, null];
  } catch (error) {
    console.error("Error obtener merchandising:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getMerchandisingByIdService(id) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    const merchandising = await merchandisingRepository.findOne({
      where: { id },
    });

    if (!merchandising) {
      return [null, "Producto no encontrado"];
    }

    return [merchandising, null];
  } catch (error) {
    console.error("Error obtener producto:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateMerchandisingService(id, updateData) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    const merchandising = await merchandisingRepository.findOne({
      where: { id },
    });

    if (!merchandising) {
      return [null, "Producto no encontrado"];
    }

    // Actualizar campos
    Object.assign(merchandising, updateData);
    merchandising.updatedAt = new Date();

    const updatedMerchandising =
      await merchandisingRepository.save(merchandising);

    return [updatedMerchandising, null];
  } catch (error) {
    console.error("Error actualizar merchandising:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function deleteMerchandisingService(id) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    const merchandising = await merchandisingRepository.findOne({
      where: { id },
    });

    if (!merchandising) {
      return [null, "Producto no encontrado"];
    }

    await merchandisingRepository.remove(merchandising);

    return [{ message: "Producto eliminado exitosamente" }, null];
  } catch (error) {
    console.error("Error eliminar merchandising:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function changeEstadoMerchandisingService(id, nuevoEstado) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    const merchandising = await merchandisingRepository.findOne({
      where: { id },
    });

    if (!merchandising) {
      return [null, "Producto no encontrado"];
    }

    // Validar estados permitidos
    const estadosPermitidos = ["activo", "inactivo"];
    if (!estadosPermitidos.includes(nuevoEstado)) {
      return [null, "Estado no válido"];
    }

    merchandising.estado = nuevoEstado;
    merchandising.updatedAt = new Date();

    const updatedMerchandising =
      await merchandisingRepository.save(merchandising);

    return [updatedMerchandising, null];
  } catch (error) {
    console.error("Error cambiar estado del producto:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function toggleDisponibleService(id) {
  try {
    const merchandisingRepository = AppDataSource.getRepository(Merchandising);

    const merchandising = await merchandisingRepository.findOne({
      where: { id },
    });

    if (!merchandising) {
      return [null, "Producto no encontrado"];
    }

    merchandising.disponible = !merchandising.disponible;
    merchandising.updatedAt = new Date();

    const updatedMerchandising =
      await merchandisingRepository.save(merchandising);

    return [updatedMerchandising, null];
  } catch (error) {
    console.error("Error cambiar disponibilidad del producto:", error);
    return [null, "Error interno del servidor"];
  }
}
