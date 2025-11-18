"use strict";
import {
  deleteUserService,
  getUserService,
  getUserGService,
  getUsersService,
  updateUserService,
  searchUserService,
  buscarRutService,
  calcularCalificacionBayesiana,
  obtenerPromedioGlobalService,
  actualizarTokenFCMService,
  obtenerUserByRut,
} from "../services/user.service.js";
import {
  userBodyValidation,
  userQueryValidation,
} from "../validations/user.validation.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { AppDataSource } from "../config/configDb.js";
import User from "../entity/user.entity.js";
import { resolveFileUrl, deleteFromS3 } from "../utils/storage.utils.js";

// Obtener repositorio de usuarios
const userRepository = AppDataSource.getRepository(User);

export async function getUser(req, res) {
  try {
    const { rut, email } = req.query;

    const { error } = userQueryValidation.validate({ rut, email });

    if (error) return handleErrorClient(res, 400, error.message);

    const [user, errorUser] = await getUserService({ rut, email });

    if (errorUser) return handleErrorClient(res, 404, errorUser);

    handleSuccess(res, 200, "Usuario encontrado", user);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getUsers(req, res) {
  try {
    const [users, errorUsers] = await getUsersService();

    if (errorUsers) return handleErrorClient(res, 404, errorUsers);

    users.length === 0
      ? handleSuccess(res, 204)
      : handleSuccess(res, 200, "Usuarios encontrados", users);
  } catch (error) {
    handleErrorServer(
      res,
      500,
      error.message,
    );
  }
}

export async function searchUser(req, res) {
  try {
    const { email } = req.query;

    const { error: queryError } = userQueryValidation.validate({ email });

    if (queryError) {
      return handleErrorClient(
        res,
        400,
        "Error de validación en la consulta",
        queryError.message,
      );
    }

    const [user, errorUser] = await searchUserService({ email });

    if (errorUser) return handleErrorClient(res, 404, errorUser);
    console.log("user", user);
    handleSuccess(res, 200, "Usuario encontrado", user);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function buscarRut(req, res) {
  try {
    const { rut } = req.query;

    const { error: queryError } = userQueryValidation.validate({ rut });
    if (queryError) {
      return handleErrorClient(
        res,
        400,  
        "Error de validación en la consulta",
        queryError.message,
      );
    }
    const [user, errorUser] = await buscarRutService({ rut });
    if (errorUser) return handleErrorClient(res, 404, errorUser);
    handleSuccess(res, 200, "Usuario encontrado", user);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateUser(req, res) {
  try {
    const { rut, email } = req.query;
    const { body } = req;

    console.log('🔍 UpdateUser - Query params:', { rut, email });
    console.log('📝 UpdateUser - Body received:', body);

    const { error: queryError } = userQueryValidation.validate({
      rut,
      email,
    });

    if (queryError) {
      console.log('❌ Query validation error:', queryError.message);
      return handleErrorClient(
        res,
        400,
        "Error de validación en la consulta",
        queryError.message,
      );
    }

    const { error: bodyError } = userBodyValidation.validate(body);

    if (bodyError) {
      console.log('❌ Body validation error:', bodyError.message);
      return handleErrorClient(
        res,
        400,
        "Error de validación en los datos enviados",
        bodyError.message,
      );
    }

    console.log('✅ Validaciones pasadas, actualizando usuario...');

    const [user, userError] = await updateUserService({ rut, email }, body);

    if (userError) {
      console.log('❌ Service error:', userError);
      return handleErrorClient(res, 400, "Error modificando al usuario", userError);
    }

    console.log('✅ Usuario actualizado exitosamente');
    handleSuccess(res, 200, "Usuario modificado correctamente", user);
  } catch (error) {
    console.error('💥 Unexpected error in updateUser:', error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function getMisVehiculos(req, res) {
  try {
    const userRut = req.user.rut;

    // Importar el servicio dentro de la función
    const { getVehiculosByUserService } = await import("../services/vehiculo.service.js");

    const [vehiculos, vehiculosError] = await getVehiculosByUserService(userRut);

    if (vehiculosError) {
      return handleErrorClient(res, 404, vehiculosError);
    }

    handleSuccess(res, 200, "Vehículos encontrados", vehiculos);
  } catch (error) {
    console.error("Error al obtener vehículos del usuario:", error);
    handleErrorServer(res, 500, error.message);
  }
}

function buildUploadUrl(req, storedValue, version) {
  const resolved = resolveFileUrl(storedValue, req);
  if (!resolved) {
    return null;
  }
  if (typeof version === "number" && !Number.isNaN(version)) {
    const separator = resolved.includes("?") ? "&" : "?";
    return `${resolved}${separator}v=${version}`;
  }
  return resolved;
}

export async function updateAvatar(req, res) {
  try {
    if (!req.file) {
      return handleErrorClient(
        res,
        400,
        "Archivo requerido",
        "Debes adjuntar una imagen en formato JPG, PNG, WEBP o GIF.",
      );
    }

    const user = await userRepository.findOne({
      where: { rut: req.user.rut },
    });

    if (!user) {
      await deleteFromS3(req.file?.location);
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    if (user.avatarPath) {
      await deleteFromS3(user.avatarPath);
    }

    user.avatarPath = req.file.location;
    user.avatarVersion = (user.avatarVersion ?? 0) + 1;
    await userRepository.save(user);

    const avatarUrl = buildUploadUrl(req, user.avatarPath, user.avatarVersion);

    handleSuccess(res, 200, "Avatar actualizado exitosamente", {
      avatarPath: user.avatarPath,
      avatarUrl,
      avatarVersion: user.avatarVersion,
    });
  } catch (error) {
    console.error("Error actualizando avatar:", error);
    await deleteFromS3(req.file?.location);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

//Bayesiano

export async function calcularCalificacion(req, res) {
  try {
    const { promedioUsuario, cantidadValoraciones, promedioGlobal, minimoValoraciones } = req.body;

    if (typeof promedioUsuario !== 'number' || typeof cantidadValoraciones !== 'number' ||
        typeof promedioGlobal !== 'number' || typeof minimoValoraciones !== 'number') {
      return handleErrorClient(res, 400, "Todos los campos deben ser números");
    }

    const calificacionAjustada = calcularCalificacionBayesiana(
      promedioUsuario,
      cantidadValoraciones,
      promedioGlobal,
      minimoValoraciones
    );

    if (calificacionAjustada === null) {
      return handleErrorServer(res, 500, "Error al calcular la calificación");
    }

    handleSuccess(res, 200, "Calificación calculada correctamente", { calificacionAjustada });
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function obtenerPromedioGlobal(req, res) {
  try {
    const [promedioGlobal, error] = await obtenerPromedioGlobalService();

    if (error) {
      console.warn("Advertencia al calcular promedio global:", error);
      // Aún así retornamos el promedio por defecto
    }

    handleSuccess(res, 200, "Promedio global obtenido correctamente", { 
      promedioGlobal: promedioGlobal,
      mensaje: error || "Cálculo exitoso"
    });
  } catch (error) {
    console.error("Error en obtenerPromedioGlobal controller:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteUser(req, res) {
  try {
    console.log('🗑️ DeleteUser (VIEJO) - Params:', req.params);
    console.log('🗑️ DeleteUser (VIEJO) - Query:', req.query);
    
    // Obtener rut del parámetro de la URL o del query
    const rutFromParams = req.params.rut;
    const { rut: rutFromQuery, email } = req.query;
    
    const rut = rutFromParams || rutFromQuery;
    console.log('🗑️ DeleteUser (VIEJO) - RUT final:', rut);

    if (!rut && !email) {
      return handleErrorClient(res, 400, "Debe proporcionar RUT o email del usuario a eliminar");
    }

    // Buscar el usuario a eliminar
    const userToDelete = await userRepository.findOne({
      where: [{ rut: rut }, { email: email }]
    });

    if (!userToDelete) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    // Protección especial: si el usuario a eliminar es directiva
    if (userToDelete.rol === 'directiva') {
      // Contar cuántas directivas hay en total
      const directivasCount = await userRepository.count({ where: { rol: 'directiva' } });
      
      if (directivasCount <= 1) {
        return handleErrorClient(res, 400, "No puedes eliminar este usuario porque debe existir al menos un usuario con rol de directiva en el sistema");
      }
    }

    // Proceder con la eliminación usando el servicio existente
    const { error } = userQueryValidation.validate({ rut, email });
    if (error) return handleErrorClient(res, 400, error.message);

    const [user, errorUser] = await deleteUserService({ rut, email });
    if (errorUser) return handleErrorClient(res, 404, errorUser);

    console.log(`✅ Usuario eliminado por directiva ${req.user.rut}: ${userToDelete.email} con rol ${userToDelete.rol}`);

    handleSuccess(res, 200, "Usuario y todas sus relaciones eliminadas exitosamente", user);
  } catch (error) {
    console.error("Error al eliminar usuario:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function actualizarTokenFCM(req, res) {
  try {
    const { fcmToken } = req.body;
    const rutUsuario = req.user.rut;

    // Validación básica
    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim() === '') {
      return handleErrorClient(res, 400, "Token FCM requerido y debe ser válido");
    }

    console.log(`🔄 Actualizando token FCM para usuario ${rutUsuario}`);

    const [result, error] = await actualizarTokenFCMService(rutUsuario, fcmToken.trim());

    if (error) {
      console.error(`❌ Error actualizando token FCM: ${error}`);
      return handleErrorClient(res, 400, error);
    }

    console.log(`✅ Token FCM actualizado exitosamente para ${rutUsuario}`);
    handleSuccess(res, 200, "Token FCM actualizado correctamente", { 
      rut: rutUsuario,
      tokenActualizado: true 
    });
  } catch (error) {
    console.error("💥 Error en actualizarTokenFCM:", error);
    handleErrorServer(res, 500, error.message);
  }
}

export async function getHistorialTransacciones(req, res) {
  try {
    const { email } = req.query;

    if (!email) {
      return handleErrorClient(res, 400, "Email requerido");
    }

    // Obtener el RUT del usuario por email
    const [userData, userError] = await getUserService({ email });
    if (userError) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    // Obtener el historial de transacciones
    const { obtenerHistorialTransaccionesService } = await import('../services/transaccion.service.js');
    const [historial, historialError] = await obtenerHistorialTransaccionesService(userData.rut);

    if (historialError) {
      console.error("Error al obtener historial:", historialError);
      // Si hay error, devolver historial vacío
      return handleSuccess(res, 200, "Historial de transacciones obtenido", []);
    }

    // Formatear las transacciones para el frontend
    const historialFormateado = historial.map(transaccion => ({
      id: transaccion.id,
      tipo: transaccion.tipo,
      concepto: transaccion.concepto,
      monto: parseFloat(transaccion.monto),
      fecha: transaccion.fecha,
      estado: transaccion.estado,
      metodo_pago: transaccion.metodo_pago,
      viaje_id: transaccion.viaje_id,
      transaccion_id: transaccion.transaccion_id
    }));

    handleSuccess(res, 200, "Historial de transacciones obtenido", historialFormateado);
  } catch (error) {
    console.error("Error en getHistorialTransacciones:", error);
    handleErrorServer(res, 500, error.message);
  }
}

/**
 * Calificar a un usuario (dar una calificación de 0-5 estrellas)
 */
export async function calificarUsuario(req, res) {
  try {
    const { rutUsuarioCalificado, calificacion } = req.body;
    const rutCalificador = req.user.rut;

    console.log(`⭐ Calificando usuario: ${rutUsuarioCalificado} con ${calificacion} estrellas por ${rutCalificador}`);

    // Validar parámetros
    if (!rutUsuarioCalificado || calificacion === undefined || calificacion === null) {
      return handleErrorClient(res, 400, "Parámetros requeridos: rutUsuarioCalificado, calificacion");
    }

    // Validar rango de calificación (0-5)
    if (calificacion < 0 || calificacion > 5) {
      return handleErrorClient(res, 400, "La calificación debe estar entre 0 y 5");
    }

    // Verificar que el usuario calificado existe
    const usuarioCalificado = await userRepository.findOne({
      where: { rut: rutUsuarioCalificado }
    });

    if (!usuarioCalificado) {
      return handleErrorClient(res, 404, "Usuario a calificar no encontrado");
    }

    // No permitir que un usuario se califique a sí mismo
    if (rutCalificador === rutUsuarioCalificado) {
      return handleErrorClient(res, 400, "No puedes calificarte a ti mismo");
    }

    // Obtener datos actuales del usuario
    const clasificacionActual = usuarioCalificado.clasificacion || 0;
    const cantidadValoraciones = usuarioCalificado.cantidadValoraciones || 0;
    const puntuacionActual = usuarioCalificado.puntuacion || 0;
    
    // Calcular nuevo promedio simple (para luego aplicar bayesiano)
    const nuevaCantidadValoraciones = cantidadValoraciones + 1;
    const nuevoPromedioSimple = ((clasificacionActual * cantidadValoraciones) + calificacion) / nuevaCantidadValoraciones;

    // Obtener el promedio global para el cálculo bayesiano
    const [promedioGlobal, errorPromedio] = await obtenerPromedioGlobalService();
    if (errorPromedio) {
      console.warn("Error obteniendo promedio global, usando valor por defecto:", errorPromedio);
    }

    // Calcular clasificación bayesiana
    const minimoValoraciones = 2; // Mismo valor que se usa en el perfil
    const clasificacionBayesiana = calcularCalificacionBayesiana(
      nuevoPromedioSimple,
      nuevaCantidadValoraciones,
      promedioGlobal,
      minimoValoraciones
    );
    
    // La clasificación final será la bayesiana si se calculó correctamente, sino el promedio simple
    const clasificacionFinal = clasificacionBayesiana !== null ? clasificacionBayesiana : nuevoPromedioSimple;

    // NUEVO: Calcular puntos a sumar según la calificación recibida
    let puntosASumar = 0;
    if (calificacion >= 4) {
      puntosASumar = 3; // 3 puntos para 4 o 5 estrellas
    } else if (calificacion === 3) {
      puntosASumar = 2; // 2 puntos para 3 estrellas
    } else if (calificacion >= 1 && calificacion <= 2) {
      puntosASumar = 1; // 1 punto para 1 o 2 estrellas
    } else if (calificacion === 0) {
      puntosASumar = 0; // 0 puntos para 0 estrellas
    }

    const nuevaPuntuacion = puntuacionActual + puntosASumar;

    console.log(`🎯 Sistema de puntos:`);
    console.log(`   Calificación recibida: ${calificacion} estrellas`);
    console.log(`   Puntos otorgados: ${puntosASumar}`);
    console.log(`   Puntuación anterior: ${puntuacionActual}`);
    console.log(`   Nueva puntuación: ${nuevaPuntuacion}`);

    // Actualizar usuario con nueva clasificación bayesiana y puntos
    await userRepository.update(
      { rut: rutUsuarioCalificado },
      {
        clasificacion: clasificacionFinal,
        cantidadValoraciones: nuevaCantidadValoraciones,
        puntuacion: nuevaPuntuacion,
        updatedAt: new Date()
      }
    );

    console.log(`✅ Usuario ${rutUsuarioCalificado} calificado:`);
    console.log(`   Clasificación anterior: ${clasificacionActual}`);
    console.log(`   Promedio simple nuevo: ${nuevoPromedioSimple.toFixed(3)}`);
    console.log(`   Clasificación bayesiana: ${clasificacionFinal.toFixed(3)}`);
    console.log(`   Cantidad valoraciones: ${nuevaCantidadValoraciones}`);
    console.log(`   Promedio global usado: ${promedioGlobal}`);
    console.log(`   Puntuación actualizada: ${puntuacionActual} → ${nuevaPuntuacion} (+${puntosASumar})`);

    handleSuccess(res, 200, "Usuario calificado exitosamente", {
      rutUsuarioCalificado,
      calificacionAnterior: clasificacionActual,
      promedioSimpleNuevo: nuevoPromedioSimple,
      clasificacionBayesiana: clasificacionFinal,
      cantidadValoraciones: nuevaCantidadValoraciones,
      calificacionOtorgada: calificacion,
      promedioGlobalUsado: promedioGlobal,
      puntosOtorgados: puntosASumar,
      puntuacionAnterior: puntuacionActual,
      nuevaPuntuacion: nuevaPuntuacion
    });

  } catch (error) {
    console.error("Error al calificar usuario:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
}

// Nueva función para cambiar rol de usuario
export async function changeUserRole(req, res) {
  try {
    const { rut, nuevoRol } = req.body;

    if (!rut || !nuevoRol) {
      return handleErrorClient(res, 400, "RUT y nuevo rol son requeridos");
    }

    // Actualizar roles válidos según la entidad User
    if (!['directiva', 'tesorera', 'entrenador', 'apoderado', 'RamaExterna'].includes(nuevoRol)) {
      return handleErrorClient(res, 400, "Rol inválido. Debe ser 'directiva', 'tesorera', 'entrenador', 'apoderado' o 'RamaExterna'");
    }

    // Buscar el usuario por RUT
    const usuario = await userRepository.findOne({ where: { rut } });

    if (!usuario) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    // Actualizar el rol
    usuario.rol = nuevoRol;
    await userRepository.save(usuario);

    handleSuccess(res, 200, "Rol de usuario actualizado exitosamente", {
      rut: usuario.rut,
      nombreCompleto: usuario.nombreCompleto,
      email: usuario.email,
      rol: usuario.rol
    });

  } catch (error) {
    console.error("Error al cambiar rol de usuario:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
}

// Nueva función para crear usuarios desde el dashboard de directiva
export async function createUserByDirectiva(req, res) {
  try {
    const { rut, nombreCompleto, email, password, rol, fechaNacimiento } = req.body;

    // Validaciones básicas
    if (!rut || !nombreCompleto || !email || !password || !rol) {
      return handleErrorClient(res, 400, "Todos los campos son requeridos: rut, nombreCompleto, email, password, rol");
    }

    // Validar que el rol sea válido
    if (!['directiva', 'tesorera', 'entrenador', 'apoderado', 'RamaExterna'].includes(rol)) {
      return handleErrorClient(res, 400, "Rol inválido. Debe ser 'directiva', 'tesorera', 'entrenador', 'apoderado' o 'RamaExterna'");
    }

    // Verificar que el usuario no exista
    const existingUserByRut = await userRepository.findOne({ where: { rut } });
    if (existingUserByRut) {
      return handleErrorClient(res, 400, "Ya existe un usuario con este RUT");
    }

    const existingUserByEmail = await userRepository.findOne({ where: { email } });
    if (existingUserByEmail) {
      return handleErrorClient(res, 400, "Ya existe un usuario con este email");
    }

    // Importar helper de encriptación
    const { encryptPassword } = await import("../helpers/bcrypt.helper.js");

    // Crear nuevo usuario
    const newUser = userRepository.create({
      rut: rut.trim(),
      nombreCompleto: nombreCompleto.trim(),
      email: email.trim().toLowerCase(),
      password: await encryptPassword(password),
      rol,
      fechaNacimiento: fechaNacimiento || null,
    });

    const savedUser = await userRepository.save(newUser);

    // Remover password del response
    const { password: _, ...userResponse } = savedUser;

    console.log(`✅ Usuario creado por directiva ${req.user.rut}: ${savedUser.email} con rol ${savedUser.rol}`);

    handleSuccess(res, 201, "Usuario creado exitosamente", userResponse);

  } catch (error) {
    console.error("Error al crear usuario:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
}

// Nueva función para actualizar usuarios desde el dashboard de directiva
export async function updateUserByDirectiva(req, res) {
  try {
    const { rut, nombreCompleto, email, rol } = req.body;

    console.log('🔧 UpdateUserByDirectiva - Body received:', req.body);
    console.log('🔧 UpdateUserByDirectiva - User making request:', req.user.rut);

    // Validaciones básicas
    if (!rut) {
      return handleErrorClient(res, 400, "El RUT es requerido para actualizar el usuario");
    }

    if (!nombreCompleto || !email || !rol) {
      return handleErrorClient(res, 400, "Todos los campos son requeridos: nombreCompleto, email, rol");
    }

    // Validar que el rol sea válido
    if (!['directiva', 'tesorera', 'entrenador', 'apoderado', 'RamaExterna'].includes(rol)) {
      return handleErrorClient(res, 400, "Rol inválido. Debe ser 'directiva', 'tesorera', 'entrenador', 'apoderado' o 'RamaExterna'");
    }

    // Buscar el usuario a actualizar
    const usuario = await userRepository.findOne({ where: { rut } });
    if (!usuario) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    // Protección especial: si el usuario actual es directiva y se quiere cambiar su rol
    if (usuario.rol === 'directiva' && rol !== 'directiva') {
      // Contar cuántas directivas hay en total
      const directivasCount = await userRepository.count({ where: { rol: 'directiva' } });
      
      if (directivasCount <= 1) {
        return handleErrorClient(res, 400, "No puedes cambiar este rol porque debe existir al menos un usuario con rol de directiva en el sistema");
      }
    }

    // Verificar que el email no esté siendo usado por otro usuario
    const existingUserByEmail = await userRepository.findOne({ 
      where: { email: email.trim().toLowerCase() } 
    });
    if (existingUserByEmail && existingUserByEmail.rut !== rut) {
      return handleErrorClient(res, 400, "Ya existe otro usuario con este email");
    }

    // Actualizar el usuario
    usuario.nombreCompleto = nombreCompleto.trim();
    usuario.email = email.trim().toLowerCase();
    usuario.rol = rol;
    usuario.updatedAt = new Date();

    const updatedUser = await userRepository.save(usuario);

    // Remover password del response
    const { password: _, ...userResponse } = updatedUser;

    console.log(`✅ Usuario actualizado por directiva ${req.user.rut}: ${updatedUser.email} con rol ${updatedUser.rol}`);

    handleSuccess(res, 200, "Usuario actualizado exitosamente", userResponse);

  } catch (error) {
    console.error("Error al actualizar usuario:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
}

// Función para eliminar usuario (solo para directiva) con protección
export const deleteUserByDirectiva = async (req, res) => {
  try {
    console.log('🗑️ DeleteUserByDirectiva - RUT a eliminar:', req.params.rut);
    
    const { rut } = req.params;

    if (!rut) {
      return handleErrorClient(res, 400, "RUT es requerido");
    }

    // Buscar el usuario a eliminar
    const usuario = await userRepository.findOne({
      where: { rut: rut.trim() },
    });

    if (!usuario) {
      return handleErrorClient(res, 404, "Usuario no encontrado");
    }

    // Si el usuario es directiva, verificar que no sea el último
    if (usuario.rol === 'directiva') {
      const directivasCount = await userRepository.count({
        where: { rol: 'directiva' }
      });

      if (directivasCount <= 1) {
        console.log(`❌ Intento de eliminar último usuario directiva por ${req.user.rut}`);
        return handleErrorClient(res, 400, "No se puede eliminar el último usuario con rol de directiva");
      }
    }

    // Eliminar el usuario
    await userRepository.delete({ rut: rut.trim() });

    console.log(`✅ Usuario eliminado por directiva ${req.user.rut}: ${usuario.email} (${usuario.rol})`);

    handleSuccess(res, 200, "Usuario eliminado exitosamente", {
      rut: usuario.rut,
      email: usuario.email,
      nombreCompleto: usuario.nombreCompleto
    });

  } catch (error) {
    console.error("Error al eliminar usuario:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
}

/**
 * @name getEntrenadores
 * @description Obtiene todos los usuarios con rol "entrenador" (endpoint público)
 * @param {Object} req - Objeto de petición
 * @param {Object} res - Objeto de respuesta
 */
export async function getEntrenadores(req, res) {
  try {
    const entrenadores = await userRepository.find({
      where: { rol: "entrenador" },
      select: ["rut", "nombreCompleto", "email", "avatar"],
      order: { nombreCompleto: "ASC" }
    });

    handleSuccess(res, 200, "Entrenadores encontrados", entrenadores);
  } catch (error) {
    console.error("Error al obtener entrenadores:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
}

