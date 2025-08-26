"use strict";
import PlanPago from "../entity/planPago.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const planPagoRepository = AppDataSource.getRepository(PlanPago);

// Crear nuevo plan de pago (Solo Directiva y Tesorera)
export async function crearPlanPago(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y tesorera pueden crear planes de pago");
    }

    const {
      nombre,
      descripcion,
      tipoCategoria,
      modalidad,
      montoBase,
      descuentoHermanos,
      descuentoProntoPago,
      incluye,
      restricciones,
      fechaInicioVigencia,
      fechaFinVigencia,
      diasGracia,
      multaMora,
      interesMora,
      observaciones
    } = req.body;

    // Verificar que no exista otro plan con el mismo nombre
    const planExistente = await planPagoRepository.findOneBy({ nombre });
    if (planExistente) {
      return handleErrorClient(res, 400, "Plan duplicado", 
        "Ya existe un plan de pago con ese nombre");
    }

    const nuevoPlan = planPagoRepository.create({
      nombre,
      descripcion,
      tipoCategoria,
      modalidad,
      montoBase,
      descuentoHermanos: descuentoHermanos || 0,
      descuentoProntoPago: descuentoProntoPago || 0,
      incluye,
      restricciones,
      fechaInicioVigencia,
      fechaFinVigencia,
      diasGracia: diasGracia || 5,
      multaMora: multaMora || 0,
      interesMora: interesMora || 0,
      creadoPorRut: req.user.rut,
      observaciones,
      activo: true
    });

    const planGuardado = await planPagoRepository.save(nuevoPlan);

    handleSuccess(res, 201, "Plan de pago creado exitosamente", planGuardado);

  } catch (error) {
    console.error("Error creando plan de pago:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener todos los planes de pago
export async function obtenerPlanesPago(req, res) {
  try {
    const { activo, categoria, modalidad } = req.query;
    const userRole = req.user.rol;

    let whereCondition = {};

    // Filtros
    if (activo !== undefined) {
      whereCondition.activo = activo === 'true';
    }
    if (categoria) {
      whereCondition.tipoCategoria = categoria;
    }
    if (modalidad) {
      whereCondition.modalidad = modalidad;
    }

    // Apoderados solo ven planes activos
    if (userRole === "apoderado") {
      whereCondition.activo = true;
    }

    const planes = await planPagoRepository.find({
      where: whereCondition,
      relations: ["creadoPor", "inscripciones"],
      order: { orden: "ASC", createdAt: "DESC" }
    });

    // Para apoderados, ocultar información sensible
    if (userRole === "apoderado") {
      planes.forEach(plan => {
        delete plan.precioCosto;
        delete plan.observaciones;
        delete plan.creadoPor;
      });
    }

    handleSuccess(res, 200, "Planes de pago obtenidos exitosamente", planes);

  } catch (error) {
    console.error("Error obteniendo planes de pago:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener plan de pago por ID
export async function obtenerPlanPagoPorId(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    const plan = await planPagoRepository.findOne({
      where: { id },
      relations: ["creadoPor", "inscripciones"]
    });

    if (!plan) {
      return handleErrorClient(res, 404, "Plan de pago no encontrado");
    }

    // Verificar acceso para apoderados
    if (userRole === "apoderado" && !plan.activo) {
      return handleErrorClient(res, 404, "Plan de pago no encontrado");
    }

    // Para apoderados, ocultar información sensible
    if (userRole === "apoderado") {
      delete plan.precioCosto;
      delete plan.observaciones;
      delete plan.creadoPor;
    }

    handleSuccess(res, 200, "Plan de pago obtenido exitosamente", plan);

  } catch (error) {
    console.error("Error obteniendo plan de pago:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar plan de pago (Solo Directiva y Tesorera)
export async function actualizarPlanPago(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y tesorera pueden actualizar planes de pago");
    }

    const plan = await planPagoRepository.findOneBy({ id });
    if (!plan) {
      return handleErrorClient(res, 404, "Plan de pago no encontrado");
    }

    const datosActualizacion = req.body;

    // Campos permitidos para actualización
    const camposPermitidos = [
      'nombre', 'descripcion', 'tipoCategoria', 'modalidad', 'montoBase',
      'descuentoHermanos', 'descuentoProntoPago', 'incluye', 'restricciones',
      'fechaFinVigencia', 'activo', 'diasGracia', 'multaMora', 'interesMora',
      'observaciones', 'orden'
    ];

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        plan[campo] = datosActualizacion[campo];
      }
    });

    plan.updatedAt = new Date();
    
    const planActualizado = await planPagoRepository.save(plan);

    handleSuccess(res, 200, "Plan de pago actualizado exitosamente", planActualizado);

  } catch (error) {
    console.error("Error actualizando plan de pago:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Desactivar plan de pago (Solo Directiva)
export async function desactivarPlanPago(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede desactivar planes de pago");
    }

    const plan = await planPagoRepository.findOne({
      where: { id },
      relations: ["inscripciones"]
    });

    if (!plan) {
      return handleErrorClient(res, 404, "Plan de pago no encontrado");
    }

    // Verificar si tiene inscripciones activas
    const inscripcionesActivas = plan.inscripciones?.filter(
      inscripcion => inscripcion.estado === "activo"
    );

    if (inscripcionesActivas && inscripcionesActivas.length > 0) {
      return handleErrorClient(res, 400, "No se puede desactivar", 
        `El plan tiene ${inscripcionesActivas.length} inscripciones activas`);
    }

    plan.activo = false;
    plan.fechaFinVigencia = new Date();
    
    const planDesactivado = await planPagoRepository.save(plan);

    handleSuccess(res, 200, "Plan de pago desactivado exitosamente", planDesactivado);

  } catch (error) {
    console.error("Error desactivando plan de pago:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estadísticas de planes de pago (Directiva, Tesorera)
export async function obtenerEstadisticasPlanes(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const totalPlanes = await planPagoRepository.count();
    const planesActivos = await planPagoRepository.count({ where: { activo: true } });
    const planesInactivos = await planPagoRepository.count({ where: { activo: false } });

    // Estadísticas por categoría
    const porCategoria = await planPagoRepository
      .createQueryBuilder("plan")
      .select("plan.tipoCategoria", "categoria")
      .addSelect("COUNT(*)", "cantidad")
      .where("plan.activo = true")
      .groupBy("plan.tipoCategoria")
      .getRawMany();

    // Estadísticas por modalidad
    const porModalidad = await planPagoRepository
      .createQueryBuilder("plan")
      .select("plan.modalidad", "modalidad")
      .addSelect("COUNT(*)", "cantidad")
      .addSelect("AVG(plan.montoBase)", "montoPromedio")
      .where("plan.activo = true")
      .groupBy("plan.modalidad")
      .getRawMany();

    // Plan más popular (con más inscripciones activas)
    const planMasPopular = await planPagoRepository
      .createQueryBuilder("plan")
      .leftJoinAndSelect("plan.inscripciones", "inscripcion")
      .select("plan.nombre", "nombre")
      .addSelect("COUNT(inscripcion.id)", "totalInscripciones")
      .where("plan.activo = true")
      .andWhere("inscripcion.estado = :estado", { estado: "activo" })
      .groupBy("plan.id")
      .orderBy("totalInscripciones", "DESC")
      .limit(1)
      .getRawOne();

    const estadisticas = {
      totales: {
        total: totalPlanes,
        activos: planesActivos,
        inactivos: planesInactivos
      },
      distribucion: {
        porCategoria,
        porModalidad
      },
      masPopular: planMasPopular
    };

    handleSuccess(res, 200, "Estadísticas de planes obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas de planes:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Calcular monto con descuentos
export async function calcularMontoConDescuentos(req, res) {
  try {
    const { planId, tieneHermanos, pagoProntoPago, cantidadHermanos = 1 } = req.body;

    const plan = await planPagoRepository.findOneBy({ id: planId, activo: true });
    if (!plan) {
      return handleErrorClient(res, 404, "Plan de pago no encontrado o inactivo");
    }

    let montoFinal = plan.montoBase;
    let descuentosAplicados = [];

    // Aplicar descuento por hermanos
    if (tieneHermanos && plan.descuentoHermanos > 0) {
      const descuentoHermanos = (plan.montoBase * plan.descuentoHermanos) / 100;
      montoFinal -= descuentoHermanos;
      descuentosAplicados.push({
        tipo: "hermanos",
        porcentaje: plan.descuentoHermanos,
        monto: descuentoHermanos
      });
    }

    // Aplicar descuento por pronto pago
    if (pagoProntoPago && plan.descuentoProntoPago > 0) {
      const descuentoPronto = (plan.montoBase * plan.descuentoProntoPago) / 100;
      montoFinal -= descuentoPronto;
      descuentosAplicados.push({
        tipo: "pronto_pago",
        porcentaje: plan.descuentoProntoPago,
        monto: descuentoPronto
      });
    }

    const resultado = {
      plan: {
        id: plan.id,
        nombre: plan.nombre,
        montoBase: plan.montoBase
      },
      calculo: {
        montoBase: plan.montoBase,
        descuentosAplicados,
        totalDescuentos: descuentosAplicados.reduce((sum, d) => sum + d.monto, 0),
        montoFinal: Math.round(montoFinal)
      }
    };

    handleSuccess(res, 200, "Monto calculado exitosamente", resultado);

  } catch (error) {
    console.error("Error calculando monto:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
