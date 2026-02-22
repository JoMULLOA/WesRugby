"use strict";
import Noticia from "../entity/noticia.entity.js";
import { AppDataSource } from "../config/configDb.js";

export async function createNoticiaService(noticiaData) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    // Crear nueva noticia
    const newNoticia = noticiaRepository.create(noticiaData);
    const savedNoticia = await noticiaRepository.save(newNoticia);

    return [savedNoticia, null];
  } catch (error) {
    console.error("Error crear noticia:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getNoticiasService(filters = {}) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    const queryBuilder = noticiaRepository.createQueryBuilder("noticia");

    // Filtros opcionales
    if (filters.estado) {
      queryBuilder.andWhere("noticia.estado = :estado", {
        estado: filters.estado,
      });
    }

    if (filters.destacada !== undefined) {
      queryBuilder.andWhere("noticia.destacada = :destacada", {
        destacada: filters.destacada,
      });
    }

    if (filters.fechaDesde) {
      queryBuilder.andWhere("noticia.fechaPublicacion >= :fechaDesde", {
        fechaDesde: filters.fechaDesde,
      });
    }

    if (filters.fechaHasta) {
      queryBuilder.andWhere("noticia.fechaPublicacion <= :fechaHasta", {
        fechaHasta: filters.fechaHasta,
      });
    }

    // Ordenar por fecha descendente y orden
    queryBuilder
      .orderBy("noticia.fechaPublicacion", "DESC")
      .addOrderBy("noticia.orden", "ASC")
      .addOrderBy("noticia.createdAt", "DESC");

    const noticias = await queryBuilder.getMany();

    return [noticias, null];
  } catch (error) {
    console.error("Error obtener noticias:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getNoticiaService(id) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    const noticia = await noticiaRepository.findOne({
      where: { id },
    });

    if (!noticia) {
      return [null, "Noticia no encontrada"];
    }

    return [noticia, null];
  } catch (error) {
    console.error("Error obtener noticia:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateNoticiaService(id, updateData) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    const noticia = await noticiaRepository.findOne({
      where: { id },
    });

    if (!noticia) {
      return [null, "Noticia no encontrada"];
    }

    // Actualizar campos
    Object.assign(noticia, updateData);
    noticia.updatedAt = new Date();

    const updatedNoticia = await noticiaRepository.save(noticia);

    return [updatedNoticia, null];
  } catch (error) {
    console.error("Error actualizar noticia:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function deleteNoticiaService(id) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    const noticia = await noticiaRepository.findOne({
      where: { id },
    });

    if (!noticia) {
      return [null, "Noticia no encontrada"];
    }

    await noticiaRepository.remove(noticia);

    return [{ message: "Noticia eliminada exitosamente" }, null];
  } catch (error) {
    console.error("Error eliminar noticia:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function changeEstadoNoticiaService(id, nuevoEstado) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    const noticia = await noticiaRepository.findOne({
      where: { id },
    });

    if (!noticia) {
      return [null, "Noticia no encontrada"];
    }

    // Validar estados permitidos
    const estadosPermitidos = ["borrador", "publicada", "archivada"];
    if (!estadosPermitidos.includes(nuevoEstado)) {
      return [null, "Estado no válido"];
    }

    noticia.estado = nuevoEstado;
    noticia.updatedAt = new Date();

    const updatedNoticia = await noticiaRepository.save(noticia);

    return [updatedNoticia, null];
  } catch (error) {
    console.error("Error cambiar estado de la noticia:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function toggleDestacadaService(id) {
  try {
    const noticiaRepository = AppDataSource.getRepository(Noticia);

    const noticia = await noticiaRepository.findOne({
      where: { id },
    });

    if (!noticia) {
      return [null, "Noticia no encontrada"];
    }

    noticia.destacada = !noticia.destacada;
    noticia.updatedAt = new Date();

    const updatedNoticia = await noticiaRepository.save(noticia);

    return [updatedNoticia, null];
  } catch (error) {
    console.error("Error cambiar destacada de la noticia:", error);
    return [null, "Error interno del servidor"];
  }
}
