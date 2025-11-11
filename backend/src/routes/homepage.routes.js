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
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";

const router = Router();

// Información del Club Wessex (almacenada en memoria)
let clubWessexInfo = {
  historia: "La rama de rugby del Wessex School nació del entusiasmo de las generaciones de 1989 y se ha mantenido como un espacio formativo que transmite los valores del colegio. A través de los años, apoderados, entrenadores y estudiantes han consolidado una comunidad que compite en torneos regionales y nacionales.\n\nHoy la directiva impulsa proyectos deportivos, académicos y sociales para seguir creciendo. Si tienes recuerdos, fotografías o hitos que desees sumar, comunícate con el equipo y forma parte de nuestra memoria colectiva.",
  correo: "rugby@wessexschool.cl",
  telefono: "+56 9 8765 4321",
  direccion: "The Wessex School, Camino El Venado 950, San Pedro.",
};

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

// Obtener información del Club Wessex (público)
router.get("/club-info", (req, res) => {
  try {
    handleSuccess(res, 200, "Información del Club Wessex obtenida exitosamente", clubWessexInfo);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
});

// Actualizar información del Club Wessex (solo directiva)
router.post("/club-info", authenticateJwt, isDirectiva, (req, res) => {
  try {
    const { historia, correo, telefono, direccion } = req.body;

    // Validación básica
    if (!historia || !correo || !telefono || !direccion) {
      return handleErrorClient(res, 400, "Todos los campos son obligatorios");
    }

    // Actualizar información
    clubWessexInfo = {
      historia: historia.trim(),
      correo: correo.trim(),
      telefono: telefono.trim(),
      direccion: direccion.trim(),
    };

    console.log("✅ Información del Club Wessex actualizada:", clubWessexInfo);

    handleSuccess(res, 200, "Información actualizada exitosamente", clubWessexInfo);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
});

export default router;