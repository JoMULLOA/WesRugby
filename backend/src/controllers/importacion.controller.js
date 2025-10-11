"use strict";
import { registerService } from "../services/auth.service.js";
import { createEstudianteService } from "../services/estudiante.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function importEstudiantesFromExcel(req, res) {
  try {
    const { estudiantes } = req.body;

    if (!estudiantes || !Array.isArray(estudiantes) || estudiantes.length === 0) {
      return handleErrorClient(res, 400, "Lista de estudiantes es requerida");
    }

    const results = {
      estudiantesCreados: [],
      apoderadosCreados: [],
      errores: [],
    };

    // Procesar cada estudiante
    for (let i = 0; i < estudiantes.length; i++) {
      const estudianteData = estudiantes[i];
      
      try {
        // Función para generar email con formato nombre.apellido0@wessex.cl
        const generateEmail = (nombreCompleto, tipo = 'apoderado') => {
          const nombres = nombreCompleto.toLowerCase().split(' ');
          const primerNombre = nombres[0];
          const primerApellido = nombres[nombres.length - 2] || nombres[nombres.length - 1];
          return `${primerNombre}.${primerApellido}0@wessex.cl`;
        };

        // 1. PRIMERO crear cuenta del apoderado principal si es necesario
        if (estudianteData.rutResponsable && estudianteData.nombreResponsable) {
          const emailResponsable = generateEmail(estudianteData.nombreResponsable);
          
          const [apoderado, apoderadoError] = await registerService({
            rut: estudianteData.rutResponsable,
            nombreCompleto: estudianteData.nombreResponsable,
            email: emailResponsable,
            password: "wessex123", // Password temporal
            rol: "apoderado",
            fechaNacimiento: null,
          });

          if (apoderadoError) {
            // Si el error es que ya existe, no es un problema crítico
            const errorMessage = typeof apoderadoError === 'string' ? apoderadoError : 
                                typeof apoderadoError === 'object' ? apoderadoError.message || JSON.stringify(apoderadoError) : 
                                String(apoderadoError);
            
            if (errorMessage.includes("ya asociado") || errorMessage.includes("ya existe")) {
              console.log(`ℹ️ Apoderado principal ya existe: ${estudianteData.rutResponsable}`);
            } else {
              console.log(`⚠️ Error creando apoderado principal: ${errorMessage}`);
            }
          } else {
            results.apoderadosCreados.push({
              ...apoderado,
              estudianteAsignado: estudianteData.nombre,
              tipoResponsable: "principal",
            });
            console.log(`✅ Apoderado principal creado: ${estudianteData.nombreResponsable} (${estudianteData.rutResponsable})`);
          }
        }

        // 2. SEGUNDO crear cuenta del apoderado secundario si es necesario
        if (estudianteData.rutResponsable2 && estudianteData.nombreResponsable2) {
          const emailResponsable2 = generateEmail(estudianteData.nombreResponsable2);
          
          const [apoderado2, apoderado2Error] = await registerService({
            rut: estudianteData.rutResponsable2,
            nombreCompleto: estudianteData.nombreResponsable2,
            email: emailResponsable2,
            password: "wessex123", // Password temporal
            rol: "apoderado",
            fechaNacimiento: null,
          });

          if (apoderado2Error) {
            // Si el error es que ya existe, no es un problema crítico
            const errorMessage2 = typeof apoderado2Error === 'string' ? apoderado2Error : 
                                 typeof apoderado2Error === 'object' ? apoderado2Error.message || JSON.stringify(apoderado2Error) : 
                                 String(apoderado2Error);
            
            if (errorMessage2.includes("ya asociado") || errorMessage2.includes("ya existe")) {
              console.log(`ℹ️ Apoderado secundario ya existe: ${estudianteData.rutResponsable2}`);
            } else {
              console.log(`⚠️ Error creando apoderado secundario: ${errorMessage2}`);
            }
          } else {
            results.apoderadosCreados.push({
              ...apoderado2,
              estudianteAsignado: estudianteData.nombre,
              tipoResponsable: "secundario",
            });
            console.log(`✅ Apoderado secundario creado: ${estudianteData.nombreResponsable2} (${estudianteData.rutResponsable2})`);
          }
        }

        // 3. FINALMENTE crear el estudiante (ahora los apoderados ya existen)
        const [estudiante, estudianteError] = await createEstudianteService({
          rut: estudianteData.rut,
          nombre: estudianteData.nombre,
          curso: estudianteData.curso,
          fechaNacimiento: estudianteData.fechaNacimiento,
          telefono: estudianteData.telefono,
          direccion: estudianteData.direccion,
          email: estudianteData.email,
          contactoEmergencia: estudianteData.contactoEmergencia,
          telefonoEmergencia: estudianteData.telefonoEmergencia,
          rutResponsable: estudianteData.rutResponsable,
          nombreResponsable: estudianteData.nombreResponsable,
          rutResponsable2: estudianteData.rutResponsable2,
          nombreResponsable2: estudianteData.nombreResponsable2,
          observaciones: estudianteData.observaciones,
          estado: "activo",
        });

        if (estudianteError) {
          results.errores.push({
            estudiante: estudianteData.nombre,
            error: `Error creando estudiante: ${estudianteError}`,
          });
          console.log(`❌ Error creando estudiante ${estudianteData.nombre}: ${estudianteError}`);
          continue;
        }

        results.estudiantesCreados.push(estudiante);
        console.log(`✅ Estudiante creado: ${estudianteData.nombre} (${estudianteData.rut})`);

      } catch (error) {
        results.errores.push({
          estudiante: estudianteData.nombre || `Registro ${i + 1}`,
          error: `Error inesperado: ${error.message}`,
        });
        console.log(`💥 Error inesperado con ${estudianteData.nombre || `Registro ${i + 1}`}: ${error.message}`);
      }
    }

    // Preparar respuesta
    const message = `Importación completada. Estudiantes: ${results.estudiantesCreados.length}, Apoderados: ${results.apoderadosCreados.length}, Errores: ${results.errores.length}`;

    handleSuccess(res, 201, message, results);

  } catch (error) {
    console.error("Error en importación masiva:", error);
    handleErrorServer(res, 500, error.message);
  }
}