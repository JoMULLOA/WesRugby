"use strict";
import {
  createMerchandisingService,
  getMerchandisingService,
  getMerchandisingByIdService,
  updateMerchandisingService,
  deleteMerchandisingService,
  changeEstadoMerchandisingService,
} from "../services/merchandising.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function createMerchandising(req, res) {
  try {
    const merchandisingData = req.body;
    const { rut, nombreCompleto } = req.user;

    // Validaciones básicas
    if (!merchandisingData.titulo || !merchandisingData.imagen || !merchandisingData.precio) {
      return handleErrorClient(res, 400, "Título, imagen y precio son obligatorios");
    }

    // Validar que el precio sea un número positivo
    if (isNaN(merchandisingData.precio) || merchandisingData.precio <= 0) {
      return handleErrorClient(res, 400, "El precio debe ser un número positivo");
    }

    // Agregar información del creador
    const dataWithCreator = {
      ...merchandisingData,
      rutCreador: rut,
      nombreCreador: nombreCompleto,
    };

    const [merchandising, error] = await createMerchandisingService(dataWithCreator);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 201, "Merchandising creado exitosamente", merchandising);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getMerchandising(req, res) {
  try {
    const { estado, precioMinimo, precioMaximo } = req.query;
    const { rol } = req.user || {};

    // Filtros según el rol (si hay usuario autenticado)
    const filters = {};
    
    if (estado) {
      filters.estado = estado;
    }
    
    if (precioMinimo && !isNaN(parseFloat(precioMinimo))) {
      filters.precioMinimo = parseFloat(precioMinimo);
    }
    
    if (precioMaximo && !isNaN(parseFloat(precioMaximo))) {
      filters.precioMaximo = parseFloat(precioMaximo);
    }

    // Si no es directiva, solo mostrar merchandising activo
    if (rol && rol !== "directiva") {
      filters.estado = "activo";
    }

    const [merchandising, error] = await getMerchandisingService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Merchandising encontrado", merchandising);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

// Endpoint público para obtener merchandising sin autenticación
export async function getMerchandisingPublico(req, res) {
  try {
    const { precioMinimo, precioMaximo, limite } = req.query;

    const filters = {
      estado: "activo", // Solo merchandising activo
    };
    
    if (precioMinimo && !isNaN(parseFloat(precioMinimo))) {
      filters.precioMinimo = parseFloat(precioMinimo);
    }
    
    if (precioMaximo && !isNaN(parseFloat(precioMaximo))) {
      filters.precioMaximo = parseFloat(precioMaximo);
    }

    const [merchandising, error] = await getMerchandisingService(filters);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    // Limitar cantidad si se especifica
    let merchandisingResult = merchandising;
    if (limite && !isNaN(parseInt(limite))) {
      merchandisingResult = merchandising.slice(0, parseInt(limite));
    }

    handleSuccess(res, 200, "Merchandising público encontrado", merchandisingResult);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getMerchandisingItem(req, res) {
  try {
    const { id } = req.params;
    const { rol } = req.user || {};

    if (!id) {
      return handleErrorClient(res, 400, "ID del merchandising es obligatorio");
    }

    const [merchandising, error] = await getMerchandisingByIdService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    // Si no es directiva, solo puede ver merchandising activo
    if (rol && rol !== "directiva" && merchandising.estado !== "activo") {
      return handleErrorClient(res, 403, "No tienes permisos para ver este merchandising");
    }

    handleSuccess(res, 200, "Merchandising encontrado", merchandising);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateMerchandising(req, res) {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!id) {
      return handleErrorClient(res, 400, "ID del merchandising es obligatorio");
    }

    // Validar precio si se está actualizando
    if (updateData.precio !== undefined) {
      if (isNaN(updateData.precio) || updateData.precio <= 0) {
        return handleErrorClient(res, 400, "El precio debe ser un número positivo");
      }
    }

    const [merchandising, error] = await updateMerchandisingService(id, updateData);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Merchandising actualizado exitosamente", merchandising);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteMerchandising(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return handleErrorClient(res, 400, "ID del merchandising es obligatorio");
    }

    const [result, error] = await deleteMerchandisingService(id);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Merchandising eliminado exitosamente", result);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function changeEstadoMerchandising(req, res) {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!id) {
      return handleErrorClient(res, 400, "ID del merchandising es obligatorio");
    }

    if (!estado) {
      return handleErrorClient(res, 400, "Estado es obligatorio");
    }

    const [merchandising, error] = await changeEstadoMerchandisingService(id, estado);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 200, `Estado del merchandising cambiado a '${estado}' exitosamente`, merchandising);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}