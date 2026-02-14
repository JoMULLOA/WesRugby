"use strict";
import { In } from "typeorm";
import Estudiante from "../entity/estudiante.entity.js";
import Justificante from "../entity/justificante.entity.js";
import { AppDataSource } from "../config/configDb.js";

/**
 * Calcula la categoría basándose en la edad del estudiante.
 * @param {Date|string} fechaNacimiento - Fecha de nacimiento del estudiante
 * @returns {string|null} - Categoría asignada (M6, M8, M10, M12) o null si no hay fecha
 */
export function calcularCategoria(fechaNacimiento) {
  if (!fechaNacimiento) return null;

  const fecha = new Date(fechaNacimiento);
  const hoy = new Date();
  
  // Calcular edad en años
  let edad = hoy.getFullYear() - fecha.getFullYear();
  const mes = hoy.getMonth() - fecha.getMonth();
  
  // Ajustar si aún no ha cumplido años este año
  if (mes < 0 || (mes === 0 && hoy.getDate() < fecha.getDate())) {
    edad--;
  }

  // Asignar categoría según edad
  if (edad >= 6 && edad <= 7) return "M6";
  if (edad >= 8 && edad <= 9) return "M8";
  if (edad >= 10 && edad <= 11) return "M10";
  if (edad >= 12) return "M12";
  
  // Si es menor de 6 años, no asignar categoría
  return null;
}

/**
 * Aplica meses de exención de justificantes aprobados a la estructura de pagos de estudiantes.
 * @param {Array} estudiantes - Lista de estudiantes con estructura pagos.
 * @returns {Promise<Array>} - Estudiantes con pagos.meses actualizados (meses exentos marcados como "justificado").
 */
async function aplicarMesesExentos(estudiantes) {
  if (!estudiantes || estudiantes.length === 0) return estudiantes;

  const justificanteRepository = AppDataSource.getRepository(Justificante);
  const rutsDependientes = estudiantes.map((e) => e.rut);

  // Consultar justificantes aprobados con mesesExencion para todos los estudiantes en un solo query
  const justificantesAprobados = await justificanteRepository.find({
    where: {
      estado: "aprobado",
      estudianteRut: In(rutsDependientes),
    },
  });

  // Mapear meses de exención por estudiante
  const mesesExencionPorRut = new Map();
  justificantesAprobados.forEach((j) => {
    if (Array.isArray(j.mesesExencion) && j.mesesExencion.length > 0) {
      const actuales = mesesExencionPorRut.get(j.estudianteRut) || new Set();
      j.mesesExencion.forEach((mesYYYYMM) => {
        // Solo considerar formato YYYY-MM válido del año 2025
        if (typeof mesYYYYMM === "string" && /^2025-(0[1-9]|1[0-2])$/u.test(mesYYYYMM)) {
          actuales.add(mesYYYYMM);
        }
      });
      mesesExencionPorRut.set(j.estudianteRut, actuales);
    }
  });

  // Aplicar exenciones a cada estudiante
  return estudiantes.map((estudiante) => {
    const mesesExentosSet = mesesExencionPorRut.get(estudiante.rut);
    if (!mesesExentosSet || mesesExentosSet.size === 0) {
      return estudiante; // Sin cambios
    }

    // Clonar estructura pagos para evitar mutación directa
    const pagos = estudiante.pagos ? { ...estudiante.pagos } : null;
    if (!pagos || !pagos.meses) return estudiante;

    const mesesActualizados = { ...pagos.meses };

    // Mapear YYYY-MM a nombre de mes en español (marzo, abril, etc.)
    const mapaMesNumeroANombre = {
      "01": "enero", "02": "febrero", "03": "marzo", "04": "abril",
      "05": "mayo", "06": "junio", "07": "julio", "08": "agosto",
      "09": "septiembre", "10": "octubre", "11": "noviembre", "12": "diciembre",
    };

    mesesExentosSet.forEach((mesYYYYMM) => {
      const mesNumero = mesYYYYMM.split("-")[1]; // Extrae "03" de "2025-03"
      const mesNombre = mapaMesNumeroANombre[mesNumero];
      if (mesNombre && mesesActualizados.hasOwnProperty(mesNombre)) {
        const estadoActual = mesesActualizados[mesNombre];
        // Solo marcar como justificado si está no pagado o vacío
        if (!estadoActual || estadoActual.toString().trim().toLowerCase() === "no pagado") {
          mesesActualizados[mesNombre] = "justificado";
        }
      }
    });

    return {
      ...estudiante,
      pagos: {
        ...pagos,
        meses: mesesActualizados,
      },
    };
  });
}

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

    // Calcular y asignar categoría automáticamente si tiene fecha de nacimiento
    if (estudianteData.fechaNacimiento && !estudianteData.categoria) {
      estudianteData.categoria = calcularCategoria(estudianteData.fechaNacimiento);
      console.log(`📊 Categoría asignada automáticamente: ${estudianteData.categoria} para estudiante con edad calculada desde ${estudianteData.fechaNacimiento}`);
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
    console.log('🔍 Obteniendo todos los estudiantes...');
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    const estudiantes = await estudianteRepository.find({
      order: {
        nombre: "ASC",
      },
    });
    
    console.log('✅ Estudiantes encontrados en DB:', estudiantes.length);

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

    // Aplicar meses exentos basados en justificantes aprobados
    const estudiantesConExenciones = await aplicarMesesExentos(estudiantesProcessed);

    return [estudiantesConExenciones, null];
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

    // Aplicar meses exentos basados en justificantes aprobados
    const estudiantesConExenciones = await aplicarMesesExentos(estudiantesProcessed);

    return [estudiantesConExenciones, null];
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

    // Aplicar meses exentos basados en justificantes aprobados
    const [estudianteConExenciones] = await aplicarMesesExentos([estudianteProcessed]);

    return [estudianteConExenciones, null];
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

    // Si se actualiza la fecha de nacimiento, recalcular categoría automáticamente
    if (updateData.fechaNacimiento) {
      const nuevaCategoria = calcularCategoria(updateData.fechaNacimiento);
      if (nuevaCategoria) {
        updateData.categoria = nuevaCategoria;
        console.log(`📊 Categoría recalculada automáticamente: ${nuevaCategoria} para estudiante ${rut}`);
      }
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

/**
 * Recalcula las categorías de todos los estudiantes basándose en su fecha de nacimiento
 * @returns {Promise<[Object, string|null]>} - Resultado de la operación
 */
export async function recalcularCategoriasService() {
  try {
    const estudianteRepository = AppDataSource.getRepository(Estudiante);

    // Obtener todos los estudiantes con fecha de nacimiento
    const estudiantes = await estudianteRepository.find({
      where: {}
    });

    let actualizados = 0;
    let sinFecha = 0;
    let sinCambios = 0;

    for (const estudiante of estudiantes) {
      if (!estudiante.fechaNacimiento) {
        sinFecha++;
        continue;
      }

      const categoriaCalculada = calcularCategoria(estudiante.fechaNacimiento);
      
      if (categoriaCalculada && categoriaCalculada !== estudiante.categoria) {
        estudiante.categoria = categoriaCalculada;
        await estudianteRepository.save(estudiante);
        actualizados++;
        console.log(`✅ Categoría actualizada para ${estudiante.nombre}: ${categoriaCalculada}`);
      } else {
        sinCambios++;
      }
    }

    const resultado = {
      total: estudiantes.length,
      actualizados,
      sinFecha,
      sinCambios
    };

    console.log(`📊 Recálculo completado:`, resultado);
    return [resultado, null];
  } catch (error) {
    console.error("❌ Error recalcular categorías:", error);
    return [null, "Error interno del servidor"];
  }
}

export const getEstudiantesByRutListService = async (rutList) => {
  try {
    console.log('🔍 Buscando estudiantes por lista de RUTs:', rutList.length);
    
    const estudianteRepository = AppDataSource.getRepository(Estudiante);
    
    const estudiantes = await estudianteRepository.find({
      where: rutList.map(rut => ({ rut }))
    });

    console.log('✅ Estudiantes encontrados por RUT list:', estudiantes.length);
    return [estudiantes, null];
  } catch (error) {
    console.error('Error obtener estudiantes por lista:', error);
    return [null, error];
  }
};