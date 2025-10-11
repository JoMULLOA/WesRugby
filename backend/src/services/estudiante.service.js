"use strict";
import Estudiante from "../entity/estudiante.entity.js";
import { AppDataSource } from "../config/configDb.js";

export async function createEstudianteService(estudianteData) {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    // Verificar si el estudiante ya existe
    const existingEstudiante = await estudianteRepository.findOne({
      where: { rut: estudianteData.rut }
    });

    if (existingEstudiante) {
      return [null, "El estudiante ya existe"];
    }

    // Crear nuevo estudiante
    const newEstudiante = estudianteRepository.create(estudianteData);
    const savedEstudiante = await estudianteRepository.save(newEstudiante);

    return [savedEstudiante, null];
  } catch (error) {
    console.error("Error crear estudiante:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getEstudiantesService() {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    const estudiantes = await estudianteRepository.find({
      order: {
        nombre: "ASC",
      },
    });

    if (!estudiantes || estudiantes.length === 0) {
      return [null, "No hay estudiantes registrados"];
    }

    // Procesar los estudiantes para separar nombres y apellidos
    const estudiantesProcessed = estudiantes.map(estudiante => {
      const nombreCompleto = estudiante.nombre || '';
      const partesNombre = nombreCompleto.trim().split(' ');
      
      const nombres = partesNombre.slice(0, 2).join(' ') || nombreCompleto;
      const apellidos = partesNombre.slice(2).join(' ') || '';

      return {
        ...estudiante,
        nombres: nombres,
        apellidos: apellidos,
      };
    });

    return [estudiantesProcessed, null];
  } catch (error) {
    console.error("Error obtener estudiantes:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getEstudiantesByApoderadoService(rutApoderado) {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    console.log("🔍 Buscando estudiantes para RUT:", rutApoderado);

    const estudiantes = await estudianteRepository.find({
      where: [
        { rutResponsable: rutApoderado },
        { rutResponsable2: rutApoderado }
      ],
      order: {
        nombre: "ASC",
      },
    });

    console.log("✅ Estudiantes encontrados en DB:", estudiantes.length);

    // Procesar los estudiantes para separar nombres y apellidos
    const estudiantesProcessed = estudiantes.map(estudiante => {
      const nombreCompleto = estudiante.nombre || '';
      const partesNombre = nombreCompleto.trim().split(' ');
      
      // Para "Ana Pérez" -> nombres: "Ana", apellidos: "Pérez"
      let nombres, apellidos;
      if (partesNombre.length >= 2) {
        // Tomar el primer elemento como nombres y el resto como apellidos
        nombres = partesNombre[0];
        apellidos = partesNombre.slice(1).join(' ');
      } else {
        nombres = nombreCompleto;
        apellidos = '';
      }

      return {
        ...estudiante,
        nombres: nombres,
        apellidos: apellidos,
      };
    });

    return [estudiantesProcessed, null];
  } catch (error) {
    console.error("Error obtener estudiantes por apoderado:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getEstudianteService(rut) {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    const estudiante = await estudianteRepository.findOne({
      where: { rut }
    });

    if (!estudiante) {
      return [null, "Estudiante no encontrado"];
    }

    // Procesar para separar nombres y apellidos
    const nombreCompleto = estudiante.nombre || '';
    const partesNombre = nombreCompleto.trim().split(' ');
    
    let nombres, apellidos;
    if (partesNombre.length >= 2) {
      // Tomar el primer elemento como nombres y el resto como apellidos
      nombres = partesNombre[0];
      apellidos = partesNombre.slice(1).join(' ');
    } else {
      nombres = nombreCompleto;
      apellidos = '';
    }

    const estudianteProcessed = {
      ...estudiante,
      nombres: nombres,
      apellidos: apellidos,
    };

    return [estudianteProcessed, null];
  } catch (error) {
    console.error("Error obtener estudiante:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateEstudianteService(rut, updateData) {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    const estudiante = await estudianteRepository.findOne({
      where: { rut }
    });

    if (!estudiante) {
      return [null, "Estudiante no encontrado"];
    }

    // Actualizar campos
    Object.assign(estudiante, updateData);
    estudiante.updatedAt = new Date();

    const updatedEstudiante = await estudianteRepository.save(estudiante);

    return [updatedEstudiante, null];
  } catch (error) {
    console.error("Error actualizar estudiante:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function deleteEstudianteService(rut) {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    const estudiante = await estudianteRepository.findOne({
      where: { rut }
    });

    if (!estudiante) {
      return [null, "Estudiante no encontrado"];
    }

    await estudianteRepository.remove(estudiante);

    return [{ message: "Estudiante eliminado exitosamente" }, null];
  } catch (error) {
    console.error("Error eliminar estudiante:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateEstudianteFotoService(rut, fotoUrl) {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    const estudiante = await estudianteRepository.findOne({
      where: { rut }
    });

    if (!estudiante) {
      return [null, "Estudiante no encontrado"];
    }

    estudiante.fotoUrl = fotoUrl;
    estudiante.updatedAt = new Date();

    const updatedEstudiante = await estudianteRepository.save(estudiante);

    return [updatedEstudiante, null];
  } catch (error) {
    console.error("Error actualizar foto de estudiante:", error);
    return [null, "Error interno del servidor"];
  }
}