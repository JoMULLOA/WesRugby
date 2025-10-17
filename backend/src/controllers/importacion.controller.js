"use strict";
import { registerService } from "../services/auth.service.js";
import { createEstudianteService, getEstudianteService, updateEstudianteService } from "../services/estudiante.service.js";
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
        // Función para generar email único con formato nombre.apellido@wessex.cl
        const generateEmail = (nombreCompleto, tipo = 'apoderado') => {
          const nombres = nombreCompleto.toLowerCase().split(' ');
          const primerNombre = nombres[0];
          const primerApellido = nombres[nombres.length - 2] || nombres[nombres.length - 1];
          // Usar un número aleatorio pequeño en lugar del timestamp para emails más limpios
          const numero = Math.floor(Math.random() * 99) + 1;
          return `${primerNombre}.${primerApellido}${numero}@wessex.cl`;
        };

        // 1. PRIMERO crear cuenta del apoderado principal si es necesario
        if (estudianteData.runResponsable && estudianteData.responsable) {
          const emailResponsable = generateEmail(estudianteData.responsable);
          
          const [apoderado, apoderadoError] = await registerService({
            rut: estudianteData.runResponsable,
            nombreCompleto: estudianteData.responsable,
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
              console.log(`ℹ️ Apoderado principal ya existe: ${estudianteData.runResponsable}`);
            } else {
              console.log(`⚠️ Error creando apoderado principal: ${errorMessage}`);
            }
          } else {
            results.apoderadosCreados.push({
              ...apoderado,
              estudianteAsignado: estudianteData.nombreCompleto,
              tipoResponsable: "principal",
            });
            console.log(`✅ Apoderado principal creado: ${estudianteData.responsable} (${estudianteData.runResponsable})`);
          }
        }

        // 2. NO crear cuentas separadas para madre y padre
        // Solo guardamos esta información como datos del estudiante
        console.log(`ℹ️ Información familiar registrada - Madre: ${estudianteData.nombreMadre || 'No especificada'}, Padre: ${estudianteData.nombrePadre || 'No especificado'}`);

        // 3. FINALMENTE crear el estudiante con los campos separados
        // Ahora tenemos nombreCompleto y run como campos separados
        let rutEstudiante = estudianteData.run || '';
        let nombreEstudiante = estudianteData.nombreCompleto || '';
        
        // Validar que ambos campos estén presentes
        if (!rutEstudiante || !nombreEstudiante) {
          throw new Error(`Faltan datos obligatorios: nombre="${nombreEstudiante}", run="${rutEstudiante}"`);
        }

        const [estudiante, estudianteError] = await createEstudianteService({
          rut: rutEstudiante,
          nombre: nombreEstudiante,
          curso: estudianteData.curso,
          fechaNacimiento: null, // No se proporciona en el nuevo formato
          telefono: estudianteData.telefonoMadre || estudianteData.telefonoPadre, // Usar teléfono de contacto disponible
          direccion: null, // No se proporciona en el nuevo formato
          email: null, // Se generará automáticamente si es necesario
          contactoEmergencia: estudianteData.nombreMadre || estudianteData.nombrePadre,
          telefonoEmergencia: estudianteData.telefonoMadre || estudianteData.telefonoPadre,
          rutResponsable: estudianteData.runResponsable,
          nombreResponsable: estudianteData.responsable,
          rutResponsable2: null, // Campo adicional para el segundo responsable si es necesario
          nombreResponsable2: null,
          observaciones: `Madre: ${estudianteData.nombreMadre || 'No especificada'}${estudianteData.telefonoMadre ? ` (${estudianteData.telefonoMadre})` : ''}, Padre: ${estudianteData.nombrePadre || 'No especificado'}${estudianteData.telefonoPadre ? ` (${estudianteData.telefonoPadre})` : ''}, Validez: ${estudianteData.validez}`,
          estado: estudianteData.validez?.toLowerCase() === 'activo' || estudianteData.validez?.toLowerCase() === 'válido' ? 'activo' : 'inactivo',
        });

        if (estudianteError) {
          // Si el estudiante ya existe, intentar actualizar sus responsables
          if (typeof estudianteError === 'string' && estudianteError.includes('ya existe')) {
            console.log(`ℹ️ El estudiante ${rutEstudiante} ya existe, actualizando responsables si es necesario`);
            const [existingEstudiante, getErr] = await getEstudianteService(rutEstudiante);
            if (getErr || !existingEstudiante) {
              results.errores.push({ estudiante: nombreEstudiante, error: `Error obteniendo estudiante existente: ${getErr || 'No encontrado'}` });
              continue;
            }

            // Preparar datos de actualización: si rutResponsable no está presente en DB, asignarlo; si está ocupado, asignar a rutResponsable2
            const updateData = {};
            if (!existingEstudiante.rutResponsable) {
              updateData.rutResponsable = estudianteData.runResponsable || existingEstudiante.rutResponsable;
              updateData.nombreResponsable = estudianteData.responsable || existingEstudiante.nombreResponsable;
            } else if (existingEstudiante.rutResponsable !== estudianteData.runResponsable && !existingEstudiante.rutResponsable2) {
              updateData.rutResponsable2 = estudianteData.runResponsable || existingEstudiante.rutResponsable2;
              updateData.nombreResponsable2 = estudianteData.responsable || existingEstudiante.nombreResponsable2;
            } else {
              // Ya está asociado con este responsable o ambos campos están ocupados
              console.log(`ℹ️ El estudiante ${rutEstudiante} ya tiene responsables asignados`);
            }

            if (Object.keys(updateData).length > 0) {
              const [updatedEstudiante, updateErr] = await updateEstudianteService(rutEstudiante, updateData);
              if (updateErr) {
                results.errores.push({ estudiante: nombreEstudiante, error: `Error actualizando estudiante existente: ${updateErr}` });
                continue;
              }
              results.estudiantesCreados.push(updatedEstudiante);
              console.log(`🔄 Estudiante actualizado con responsable: ${nombreEstudiante} (${rutEstudiante})`);
            } else {
              results.estudiantesCreados.push(existingEstudiante);
            }

            continue;
          }

          results.errores.push({
            estudiante: nombreEstudiante,
            error: `Error creando estudiante: ${estudianteError}`,
          });
          console.log(`❌ Error creando estudiante ${nombreEstudiante}: ${estudianteError}`);
          continue;
        }

        results.estudiantesCreados.push(estudiante);
        console.log(`✅ Estudiante creado: ${nombreEstudiante} (${rutEstudiante})`);

      } catch (error) {
        results.errores.push({
          estudiante: estudianteData.nombreCompleto || `Registro ${i + 1}`,
          error: `Error inesperado: ${error.message}`,
        });
        console.log(`💥 Error inesperado con ${estudianteData.nombreCompleto || `Registro ${i + 1}`}: ${error.message}`);
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