"use strict";
import { AppDataSource } from "../config/configDb.js";
import { handleErrorClient, handleErrorServer, handleSuccess } from "../handlers/responseHandlers.js";

// Entidad simple para la información del club (se puede almacenar en una tabla o en un JSON)
// Por ahora usaremos un objeto en memoria, pero debería estar en la base de datos
let clubInfo = {
  nombre: "Wessex Rugby Club",
  mision: "Fomentar el desarrollo deportivo, físico y valórico de nuestros estudiantes a través del rugby.",
  vision: "Ser reconocidos como un club formativo de excelencia que promueve valores y competitividad.",
  historia: "Fundado en 2010, Wessex Rugby Club ha sido un pilar en la formación de jóvenes rugbiers.",
  direccion: "Santiago, Chile",
  telefono: "+56 9 1234 5678",
  email: "contacto@wessexrugby.cl",
  facebook: "https://facebook.com/wessexrugby",
  instagram: "@wessexrugby",
  twitter: "@wessexrugby",
  website: "https://www.wessexrugby.cl",
};

/**
 * Obtiene la información del club
 * @param {Request} req - Objeto de petición
 * @param {Response} res - Objeto de respuesta
 */
export async function getClubInfo(req, res) {
  try {
    return handleSuccess(res, 200, "Información del club obtenida exitosamente", clubInfo);
  } catch (error) {
    console.error("Error al obtener información del club:", error);
    return handleErrorServer(res, 500, error.message);
  }
}

/**
 * Actualiza la información del club
 * @param {Request} req - Objeto de petición
 * @param {Response} res - Objeto de respuesta
 */
export async function updateClubInfo(req, res) {
  try {
    const {
      nombre,
      mision,
      vision,
      historia,
      direccion,
      telefono,
      email,
      facebook,
      instagram,
      twitter,
      website,
    } = req.body;

    // Validación básica
    if (!nombre || nombre.trim() === "") {
      return handleErrorClient(res, 400, "El nombre del club es obligatorio");
    }

    // Actualizar la información (permitir valores vacíos excepto nombre)
    clubInfo = {
      nombre: nombre.trim(),
      mision: mision?.trim() ?? "",
      vision: vision?.trim() ?? "",
      historia: historia?.trim() ?? "",
      direccion: direccion?.trim() ?? "",
      telefono: telefono?.trim() ?? "",
      email: email?.trim() ?? "",
      facebook: facebook?.trim() ?? "",
      instagram: instagram?.trim() ?? "",
      twitter: twitter?.trim() ?? "",
      website: website?.trim() ?? "",
    };

    console.log("✅ Información del club actualizada:", clubInfo);

    return handleSuccess(res, 200, "Información actualizada exitosamente", clubInfo);
  } catch (error) {
    console.error("Error al actualizar información del club:", error);
    return handleErrorServer(res, 500, error.message);
  }
}
