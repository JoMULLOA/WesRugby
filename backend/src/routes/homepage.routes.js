"use strict";
import { Router } from "express";
import { 
  getNoticiasService 
} from "../services/noticia.service.js";
import { 
  getAuspiciadoresService 
} from "../services/auspiciador.service.js";
import { 
  getMerchandisingService 
} from "../services/merchandising.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const router = Router();

// Endpoint público para obtener toda la información de la página de inicio
export async function getHomepage(req, res) {
  try {
    const { noticiasLimit = 6, merchandisingLimit = 8 } = req.query;

    // Obtener noticias publicadas
    const [noticias, noticiasError] = await getNoticiasService({ 
      estado: "publicada" 
    });
    
    if (noticiasError) {
      return handleErrorClient(res, 404, "Error al obtener noticias: " + noticiasError);
    }

    // Obtener auspiciadores activos
    const [auspiciadores, auspiciadoresError] = await getAuspiciadoresService({ 
      estado: "activo" 
    });
    
    if (auspiciadoresError) {
      return handleErrorClient(res, 404, "Error al obtener auspiciadores: " + auspiciadoresError);
    }

    // Obtener merchandising activo
    const [merchandising, merchandisingError] = await getMerchandisingService({ 
      estado: "activo" 
    });
    
    if (merchandisingError) {
      return handleErrorClient(res, 404, "Error al obtener merchandising: " + merchandisingError);
    }

    // Preparar respuesta con límites opcionales
    const response = {
      noticias: {
        destacadas: noticias.filter(n => n.destacada),
        recientes: noticias
          .filter(n => !n.destacada)
          .slice(0, parseInt(noticiasLimit) - noticias.filter(n => n.destacada).length),
        total: noticias.length
      },
      auspiciadores: {
        items: auspiciadores,
        total: auspiciadores.length
      },
      merchandising: {
        items: merchandising.slice(0, parseInt(merchandisingLimit)),
        total: merchandising.length
      }
    };

    handleSuccess(res, 200, "Información pública obtenida exitosamente", response);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

// Ruta pública para homepage
router.get("/", getHomepage);

export default router;