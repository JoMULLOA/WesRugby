"use strict";
import Inscripcion from "../entity/inscripcion.entity.js";
import PlanPago from "../entity/planPago.entity.js";
import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const inscripcionRepository = AppDataSource.getRepository(Inscripcion);
const planPagoRepository = AppDataSource.getRepository(PlanPago);
const userRepository = AppDataSource.getRepository(User);

// Generar código único de alumno
function generarCodigoAlumno() {
  const año = new Date().getFullYear();
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return `WR${año}${random}`;
}

// Crear nueva inscripción (Entrenador, Apoderado)
export async function crearInscripcion(req, res) {
  try {
    const {
      // Datos del alumno
      nombre,
      apellidos, 
      rutAlumno,
      fechaNacimiento,
      genero,
      direccion,
      telefono,
      email,
      contactoEmergencia,
      telefonoEmergencia,
      
      // Datos del tutor
      nombreTutor,
      rutTutor,
      telefonoTutor,
      emailTutor,
      relacionAlumno,
      
      // Información médica
      problemasSalud,
      autorizacionMedica,
      
      // Plan de pago
      planPagoId,
      
      // Observaciones
      observaciones
    } = req.body;

    // Verificar si el alumno ya existe
    const alumnoExistente = await inscripcionRepository.findOneBy({ rutAlumno });
    if (alumnoExistente) {
      return handleErrorClient(res, 400, "El alumno ya está inscrito", 
        "Ya existe una inscripción con este RUT de alumno");
    }

    // Verificar que el plan de pago existe (si se especifica)
    if (planPagoId) {
      const planExiste = await planPagoRepository.findOneBy({ id: planPagoId, activo: true });
      if (!planExiste) {
        return handleErrorClient(res, 400, "Plan de pago no válido", 
          "El plan de pago especificado no existe o no está activo");
      }
    }

    // Generar código único de alumno
    let codigoAlumno;
    let codigoUnico = false;
    let intentos = 0;
    
    while (!codigoUnico && intentos < 10) {
      codigoAlumno = generarCodigoAlumno();
      const existeCodigo = await inscripcionRepository.findOneBy({ codigoAlumno });
      if (!existeCodigo) {
        codigoUnico = true;
      }
      intentos++;
    }

    if (!codigoUnico) {
      return handleErrorServer(res, 500, "Error generando código único de alumno");
    }

    // Crear la inscripción
    const nuevaInscripcion = inscripcionRepository.create({
      codigoAlumno,
      nombre,
      apellidos,
      rutAlumno,
      fechaNacimiento,
      genero,
      direccion,
      telefono,
      email,
      contactoEmergencia,
      telefonoEmergencia,
      nombreTutor,
      rutTutor,
      telefonoTutor,
      emailTutor,
      relacionAlumno,
      problemasSalud,
      autorizacionMedica: autorizacionMedica || false,
      planPagoId,
      creadoPorRut: req.user.rut,
      observaciones,
      documentosRequeridos: [
        { documento: "Certificado de nacimiento", estado: "pendiente" },
        { documento: "Certificado médico", estado: "pendiente" },
        { documento: "Autorización apoderado", estado: "pendiente" }
      ]
    });

    const inscripcionGuardada = await inscripcionRepository.save(nuevaInscripcion);

    // Cargar la inscripción completa con relaciones
    const inscripcionCompleta = await inscripcionRepository.findOne({
      where: { id: inscripcionGuardada.id },
      relations: ["planPago", "creadoPor"]
    });

    handleSuccess(res, 201, "Inscripción creada exitosamente", inscripcionCompleta);

  } catch (error) {
    console.error("Error creando inscripción:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener todas las inscripciones (con filtros según rol)
export async function obtenerInscripciones(req, res) {
  try {
    const { estado, categoria, page = 1, limit = 20 } = req.query;
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    let whereCondition = {};

    // Filtros según el rol del usuario
    if (userRole === "apoderado") {
      // Apoderados solo ven sus propios hijos
      whereCondition.rutTutor = userRut;
    } else if (userRole === "entrenador") {
      // Entrenadores ven inscripciones activas y pendientes
      whereCondition.estado = estado || "activo";
    }
    // Directiva y tesorera ven todas

    // Aplicar filtros adicionales
    if (estado && userRole !== "apoderado") {
      whereCondition.estado = estado;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [inscripciones, total] = await inscripcionRepository.findAndCount({
      where: whereCondition,
      relations: ["planPago", "creadoPor", "aprobadoPor"],
      order: { createdAt: "DESC" },
      skip,
      take: parseInt(limit)
    });

    handleSuccess(res, 200, "Inscripciones obtenidas exitosamente", {
      inscripciones,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error("Error obteniendo inscripciones:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener inscripción por ID
export async function obtenerInscripcionPorId(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const inscripcion = await inscripcionRepository.findOne({
      where: { id },
      relations: ["planPago", "creadoPor", "aprobadoPor", "asistencias", "pagos"]
    });

    if (!inscripcion) {
      return handleErrorClient(res, 404, "Inscripción no encontrada");
    }

    // Verificar permisos según rol
    if (userRole === "apoderado" && inscripcion.rutTutor !== userRut) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo puedes ver inscripciones de tus hijos");
    }

    handleSuccess(res, 200, "Inscripción obtenida exitosamente", inscripcion);

  } catch (error) {
    console.error("Error obteniendo inscripción:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar inscripción (Entrenador, Directiva)
export async function actualizarInscripcion(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;
    const datosActualizacion = req.body;

    if (userRole === "apoderado") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Los apoderados no pueden editar inscripciones directamente");
    }

    const inscripcion = await inscripcionRepository.findOneBy({ id });
    if (!inscripcion) {
      return handleErrorClient(res, 404, "Inscripción no encontrada");
    }

    // Actualizar campos permitidos
    const camposPermitidos = [
      'nombre', 'apellidos', 'direccion', 'telefono', 'email',
      'contactoEmergencia', 'telefonoEmergencia', 'nombreTutor',
      'telefonoTutor', 'emailTutor', 'relacionAlumno', 'problemasSalud',
      'autorizacionMedica', 'planPagoId', 'observaciones'
    ];

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        inscripcion[campo] = datosActualizacion[campo];
      }
    });

    inscripcion.updatedAt = new Date();
    
    const inscripcionActualizada = await inscripcionRepository.save(inscripcion);

    handleSuccess(res, 200, "Inscripción actualizada exitosamente", inscripcionActualizada);

  } catch (error) {
    console.error("Error actualizando inscripción:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Aprobar inscripción (Directiva, Entrenador)
export async function aprobarInscripcion(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (!["directiva", "entrenador"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y entrenadores pueden aprobar inscripciones");
    }

    const inscripcion = await inscripcionRepository.findOneBy({ id });
    if (!inscripcion) {
      return handleErrorClient(res, 404, "Inscripción no encontrada");
    }

    if (inscripcion.estado !== "pendiente") {
      return handleErrorClient(res, 400, "Estado no válido", 
        "Solo se pueden aprobar inscripciones pendientes");
    }

    inscripcion.estado = "activo";
    inscripcion.fechaAprobacion = new Date();
    inscripcion.aprobadoPorRut = req.user.rut;

    const inscripcionAprobada = await inscripcionRepository.save(inscripcion);

    handleSuccess(res, 200, "Inscripción aprobada exitosamente", inscripcionAprobada);

  } catch (error) {
    console.error("Error aprobando inscripción:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Dar de baja inscripción (Directiva, Entrenador)
export async function darDeBajaInscripcion(req, res) {
  try {
    const { id } = req.params;
    const { motivoBaja } = req.body;
    const userRole = req.user.rol;

    if (!["directiva", "entrenador"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y entrenadores pueden dar de baja inscripciones");
    }

    const inscripcion = await inscripcionRepository.findOneBy({ id });
    if (!inscripcion) {
      return handleErrorClient(res, 404, "Inscripción no encontrada");
    }

    if (inscripcion.estado === "baja") {
      return handleErrorClient(res, 400, "Estado no válido", 
        "La inscripción ya está dada de baja");
    }

    inscripcion.estado = "baja";
    inscripcion.fechaBaja = new Date();
    inscripcion.motivoBaja = motivoBaja;

    const inscripcionDadaDeBaja = await inscripcionRepository.save(inscripcion);

    handleSuccess(res, 200, "Inscripción dada de baja exitosamente", inscripcionDadaDeBaja);

  } catch (error) {
    console.error("Error dando de baja inscripción:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Estadísticas de inscripciones (Directiva, Entrenador)
export async function obtenerEstadisticasInscripciones(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "entrenador", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const totalInscripciones = await inscripcionRepository.count();
    const activos = await inscripcionRepository.count({ where: { estado: "activo" } });
    const pendientes = await inscripcionRepository.count({ where: { estado: "pendiente" } });
    const bajas = await inscripcionRepository.count({ where: { estado: "baja" } });
    const inactivos = await inscripcionRepository.count({ where: { estado: "inactivo" } });

    // Estadísticas por género
    const masculinos = await inscripcionRepository.count({ 
      where: { genero: "masculino", estado: "activo" } 
    });
    const femeninos = await inscripcionRepository.count({ 
      where: { genero: "femenino", estado: "activo" } 
    });

    // Inscripciones por mes (últimos 12 meses)
    const fechaInicio = new Date();
    fechaInicio.setMonth(fechaInicio.getMonth() - 12);

    const inscripcionesPorMes = await inscripcionRepository
      .createQueryBuilder("inscripcion")
      .select("DATE_TRUNC('month', inscripcion.fechaInscripcion) as mes")
      .addSelect("COUNT(*) as cantidad")
      .where("inscripcion.fechaInscripcion >= :fechaInicio", { fechaInicio })
      .groupBy("DATE_TRUNC('month', inscripcion.fechaInscripcion)")
      .orderBy("mes", "ASC")
      .getRawMany();

    const estadisticas = {
      totales: {
        total: totalInscripciones,
        activos,
        pendientes,
        bajas,
        inactivos
      },
      genero: {
        masculinos,
        femeninos
      },
      tendencia: inscripcionesPorMes
    };

    handleSuccess(res, 200, "Estadísticas obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
