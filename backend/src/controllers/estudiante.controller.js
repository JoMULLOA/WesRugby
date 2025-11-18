"use strict";
import { AppDataSource } from "../config/configDb.js";
import Estudiante from "../entity/estudiante.entity.js";
import {
  createEstudianteService,
  getEstudiantesService,
  getEstudiantesByApoderadoService,
  getEstudianteService,
  updateEstudianteService,
  deleteEstudianteService,
  updateEstudianteFotoService,
} from "../services/estudiante.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function createEstudiante(req, res) {
  try {
    const estudianteData = req.body;

    // Validaciones básicas
    if (!estudianteData.rut || !estudianteData.nombre || !estudianteData.curso) {
      return handleErrorClient(res, 400, "RUT, nombre y curso son obligatorios");
    }

    const [estudiante, error] = await createEstudianteService(estudianteData);

    if (error) {
      return handleErrorClient(res, 400, error);
    }

    handleSuccess(res, 201, "Estudiante creado exitosamente", estudiante);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getEstudiantes(req, res) {
  try {
    console.log('📚 Controlador getEstudiantes llamado por:', req.user.email);
    const [estudiantes, error] = await getEstudiantesService();

    if (error) {
      console.log('❌ Error en servicio:', error);
      return handleErrorClient(res, 404, error);
    }

    console.log('✅ Estudiantes obtenidos:', estudiantes.length);
    estudiantes.length === 0
      ? handleSuccess(res, 204)
      : handleSuccess(res, 200, "Estudiantes encontrados", estudiantes);
  } catch (error) {
    console.error('❌ Error en controlador:', error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function getEstudiantesByApoderado(req, res) {
  try {
    // Si no se proporciona RUT en la query, usar el RUT del usuario autenticado
    const rutApoderado = req.query.rut || req.user.rut;

    if (!rutApoderado) {
      return handleErrorClient(res, 400, "RUT del apoderado es obligatorio");
    }

    // Si es apoderado, solo puede ver sus propios estudiantes
    if (req.user.rol === "apoderado" && req.query.rut && req.query.rut !== req.user.rut) {
      return handleErrorClient(res, 403, "Solo puedes ver tus propios estudiantes");
    }

    const [estudiantes, error] = await getEstudiantesByApoderadoService(rutApoderado);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Estudiantes del apoderado encontrados", estudiantes);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getMisEstudiantes(req, res) {
  try {
    // Usar el RUT del usuario autenticado directamente
    const rutApoderado = req.user.rut;

    if (!rutApoderado) {
      return handleErrorClient(res, 400, "Usuario no autenticado correctamente");
    }

    console.log("🔍 Buscando estudiantes para apoderado:", rutApoderado);

    const [estudiantes, error] = await getEstudiantesByApoderadoService(rutApoderado);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    console.log("✅ Estudiantes encontrados:", estudiantes?.length || 0);
    console.log("📊 Datos de estudiantes:", JSON.stringify(estudiantes, null, 2));

    handleSuccess(res, 200, "Mis estudiantes encontrados", estudiantes);
  } catch (error) {
    console.error("❌ Error en getMisEstudiantes:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function getEstudiante(req, res) {
  try {
    const { rut } = req.params;

    if (!rut) {
      return handleErrorClient(res, 400, "RUT es obligatorio");
    }

    const [estudiante, error] = await getEstudianteService(rut);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Estudiante encontrado", estudiante);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateEstudiante(req, res) {
  try {
    const { rut } = req.params;
    const updateData = req.body;
    const userRut = req.user.rut;
    const userRol = req.user.rol;

    if (!rut) {
      return handleErrorClient(res, 400, "RUT es obligatorio");
    }

    // Si es apoderado, verificar que puede modificar este estudiante
    if (userRol === "apoderado") {
      const estudianteRepository = AppDataSource.getRepository(Estudiante);
      const estudiante = await estudianteRepository.findOne({ where: { rut } });
      
      if (!estudiante) {
        return handleErrorClient(res, 404, "Estudiante no encontrado");
      }

      // Verificar que el usuario es responsable del estudiante
      // Puede ser por los campos rutResponsable registrados
      const esResponsable = 
        estudiante.rutResponsable === userRut ||
        estudiante.rutResponsable2 === userRut;

      if (!esResponsable) {
        return handleErrorClient(res, 403, "No tienes permisos para modificar este estudiante");
      }
    }

    const [estudiante, error] = await updateEstudianteService(rut, updateData);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Estudiante actualizado exitosamente", estudiante);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteEstudiante(req, res) {
  try {
    const { rut } = req.params;

    if (!rut) {
      return handleErrorClient(res, 400, "RUT es obligatorio");
    }

    const [result, error] = await deleteEstudianteService(rut);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Estudiante eliminado exitosamente", result);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateEstudianteFoto(req, res) {
  try {
    const { rut } = req.params;
    const { fotoUrl } = req.body;
    const userRut = req.user.rut;
    const userRol = req.user.rol;

    if (!rut) {
      return handleErrorClient(res, 400, "RUT es obligatorio");
    }

    if (!fotoUrl) {
      return handleErrorClient(res, 400, "URL de la foto es obligatoria");
    }

    // Si es apoderado, verificar que puede modificar este estudiante
    if (userRol === "apoderado") {
      const [estudiante, errorEstudiante] = await getEstudianteService(rut);
      
      if (errorEstudiante) {
        return handleErrorClient(res, 404, errorEstudiante);
      }

      // Verificar que el usuario es responsable del estudiante
      if (estudiante.rutResponsable !== userRut && estudiante.rutResponsable2 !== userRut) {
        return handleErrorClient(res, 403, "No tienes permisos para modificar la foto de este estudiante");
      }
    }

    const [estudiante, error] = await updateEstudianteFotoService(rut, fotoUrl);

    if (error) {
      return handleErrorClient(res, 404, error);
    }

    handleSuccess(res, 200, "Foto del estudiante actualizada exitosamente", estudiante);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}