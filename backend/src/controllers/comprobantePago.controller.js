"use strict";
import ComprobantePago from "../entity/comprobantePago.entity.js";
import User from "../entity/user.entity.js";
import PlanPago from "../entity/planPago.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const comprobanteRepository = AppDataSource.getRepository(ComprobantePago);
const userRepository = AppDataSource.getRepository(User);
const planPagoRepository = AppDataSource.getRepository(PlanPago);

// Crear comprobante de pago
export async function crearComprobantePago(req, res) {
  try {
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const {
      rutPagador,
      planPagoId,
      metodoPago,
      numeroTransaccion,
      monto,
      fechaPago,
      fechaVencimiento,
      concepto,
      periodoFacturado,
      observaciones,
      archivoComprobante
    } = req.body;

    // Verificar autorización
    if (userRole === "apoderado") {
      // Apoderados solo pueden crear comprobantes para ellos o sus hijos
      if (rutPagador !== userRut) {
        const hijo = await userRepository.findOne({
          where: { rut: rutPagador, rutApoderado: userRut }
        });
        if (!hijo) {
          return handleErrorClient(res, 403, "No autorizado", 
            "Solo puede crear comprobantes para usted o sus hijos");
        }
      }
    } else if (!["tesorera", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    // Verificar que el pagador existe
    const pagador = await userRepository.findOneBy({ rut: rutPagador });
    if (!pagador) {
      return handleErrorClient(res, 404, "Usuario pagador no encontrado");
    }

    // Verificar plan de pago si se proporciona
    let planPago = null;
    if (planPagoId) {
      planPago = await planPagoRepository.findOneBy({ id: planPagoId, activo: true });
      if (!planPago) {
        return handleErrorClient(res, 404, "Plan de pago no encontrado o inactivo");
      }
    }

    // Verificar duplicado por número de transacción
    if (numeroTransaccion) {
      const comprobanteExistente = await comprobanteRepository.findOneBy({ 
        numeroTransaccion 
      });
      if (comprobanteExistente) {
        return handleErrorClient(res, 400, "Número de transacción duplicado");
      }
    }

    const nuevoComprobante = comprobanteRepository.create({
      rutPagador,
      planPagoId,
      metodoPago,
      numeroTransaccion,
      monto,
      fechaPago,
      fechaVencimiento,
      concepto,
      periodoFacturado,
      observaciones,
      archivoComprobante,
      creadoPorRut: req.user.rut,
      estado: userRole === "apoderado" ? "pendiente_revision" : "validado"
    });

    const comprobanteGuardado = await comprobanteRepository.save(nuevoComprobante);

    const comprobanteCompleto = await comprobanteRepository.findOne({
      where: { id: comprobanteGuardado.id },
      relations: ["pagador", "planPago", "creadoPor"]
    });

    handleSuccess(res, 201, "Comprobante de pago creado exitosamente", comprobanteCompleto);

  } catch (error) {
    console.error("Error creando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener comprobantes de pago
export async function obtenerComprobantesPago(req, res) {
  try {
    const userRole = req.user.rol;
    const userRut = req.user.rut;
    
    const {
      estado,
      metodoPago,
      fechaInicio,
      fechaFin,
      rutPagador,
      planPagoId,
      limite = 50,
      pagina = 1
    } = req.query;

    let whereCondition = {};

    // Filtros por rol
    if (userRole === "apoderado") {
      // Apoderados solo ven sus comprobantes y de sus hijos
      const hijos = await userRepository.find({
        where: { rutApoderado: userRut }
      });
      
      const rutsPermitidos = [userRut, ...hijos.map(hijo => hijo.rut)];
      whereCondition.rutPagador = { $in: rutsPermitidos };
    } else if (rutPagador) {
      whereCondition.rutPagador = rutPagador;
    }

    // Aplicar filtros
    if (estado) {
      whereCondition.estado = estado;
    }

    if (metodoPago) {
      whereCondition.metodoPago = metodoPago;
    }

    if (planPagoId) {
      whereCondition.planPagoId = planPagoId;
    }

    if (fechaInicio && fechaFin) {
      whereCondition.fechaPago = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    const skip = (parseInt(pagina) - 1) * parseInt(limite);

    const [comprobantes, total] = await comprobanteRepository.findAndCount({
      where: whereCondition,
      relations: ["pagador", "planPago", "creadoPor"],
      order: { fechaPago: "DESC", createdAt: "DESC" },
      take: parseInt(limite),
      skip: skip
    });

    const resultado = {
      comprobantes,
      paginacion: {
        total,
        pagina: parseInt(pagina),
        limite: parseInt(limite),
        totalPaginas: Math.ceil(total / parseInt(limite))
      }
    };

    handleSuccess(res, 200, "Comprobantes obtenidos exitosamente", resultado);

  } catch (error) {
    console.error("Error obteniendo comprobantes:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Validar comprobante (Tesorera, Directiva)
export async function validarComprobante(req, res) {
  try {
    const { id } = req.params;
    const { estado, observacionesValidacion } = req.body;
    const userRole = req.user.rol;

    if (!["tesorera", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo tesorera y directiva pueden validar comprobantes");
    }

    const comprobante = await comprobanteRepository.findOne({
      where: { id },
      relations: ["pagador", "planPago"]
    });

    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    // Estados válidos para validación
    const estadosValidos = ["validado", "rechazado", "pendiente_revision"];
    if (!estadosValidos.includes(estado)) {
      return handleErrorClient(res, 400, "Estado inválido");
    }

    comprobante.estado = estado;
    comprobante.fechaValidacion = new Date();
    comprobante.validadoPorRut = req.user.rut;
    comprobante.observacionesValidacion = observacionesValidacion;

    const comprobanteActualizado = await comprobanteRepository.save(comprobante);

    const comprobanteCompleto = await comprobanteRepository.findOne({
      where: { id: comprobanteActualizado.id },
      relations: ["pagador", "planPago", "creadoPor", "validadoPor"]
    });

    handleSuccess(res, 200, "Comprobante validado exitosamente", comprobanteCompleto);

  } catch (error) {
    console.error("Error validando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar comprobante
export async function actualizarComprobante(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const comprobante = await comprobanteRepository.findOne({
      where: { id },
      relations: ["pagador"]
    });

    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    // Verificar autorización
    if (userRole === "apoderado") {
      // Apoderados solo pueden actualizar si son el creador o el pagador
      if (comprobante.creadoPorRut !== userRut && comprobante.rutPagador !== userRut) {
        const hijo = await userRepository.findOne({
          where: { rut: comprobante.rutPagador, rutApoderado: userRut }
        });
        if (!hijo) {
          return handleErrorClient(res, 403, "No autorizado");
        }
      }

      // Apoderados solo pueden actualizar comprobantes pendientes
      if (comprobante.estado !== "pendiente_revision") {
        return handleErrorClient(res, 400, 
          "Solo se pueden actualizar comprobantes pendientes de revisión");
      }
    } else if (!["tesorera", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const datosActualizacion = req.body;

    // Campos permitidos según rol
    let camposPermitidos = [];
    if (userRole === "apoderado") {
      camposPermitidos = [
        'metodoPago', 'numeroTransaccion', 'monto', 'fechaPago',
        'concepto', 'observaciones', 'archivoComprobante'
      ];
    } else {
      camposPermitidos = [
        'metodoPago', 'numeroTransaccion', 'monto', 'fechaPago', 'fechaVencimiento',
        'concepto', 'periodoFacturado', 'observaciones', 'archivoComprobante', 'estado'
      ];
    }

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        comprobante[campo] = datosActualizacion[campo];
      }
    });

    comprobante.updatedAt = new Date();
    
    const comprobanteActualizado = await comprobanteRepository.save(comprobante);

    const comprobanteCompleto = await comprobanteRepository.findOne({
      where: { id: comprobanteActualizado.id },
      relations: ["pagador", "planPago", "creadoPor"]
    });

    handleSuccess(res, 200, "Comprobante actualizado exitosamente", comprobanteCompleto);

  } catch (error) {
    console.error("Error actualizando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estadísticas de pagos
export async function obtenerEstadisticasPagos(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["tesorera", "directiva"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { fechaInicio, fechaFin, planPagoId } = req.query;

    let whereCondition = {};

    if (fechaInicio && fechaFin) {
      whereCondition.fechaPago = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    if (planPagoId) {
      whereCondition.planPagoId = planPagoId;
    }

    // Total de comprobantes
    const totalComprobantes = await comprobanteRepository.count({ where: whereCondition });

    // Por estado
    const porEstado = await comprobanteRepository
      .createQueryBuilder("comprobante")
      .select("comprobante.estado", "estado")
      .addSelect("COUNT(*)", "cantidad")
      .addSelect("SUM(comprobante.monto)", "montoTotal")
      .where(whereCondition)
      .groupBy("comprobante.estado")
      .getRawMany();

    // Por método de pago
    const porMetodoPago = await comprobanteRepository
      .createQueryBuilder("comprobante")
      .select("comprobante.metodoPago", "metodo")
      .addSelect("COUNT(*)", "cantidad")
      .addSelect("SUM(comprobante.monto)", "montoTotal")
      .where(whereCondition)
      .andWhere("comprobante.estado = :estado", { estado: "validado" })
      .groupBy("comprobante.metodoPago")
      .getRawMany();

    // Ingresos por mes (últimos 12 meses)
    const ingresosMensuales = await comprobanteRepository
      .createQueryBuilder("comprobante")
      .select("DATE_FORMAT(comprobante.fechaPago, '%Y-%m')", "mes")
      .addSelect("SUM(comprobante.monto)", "ingresos")
      .addSelect("COUNT(*)", "cantidad")
      .where("comprobante.estado = :estado", { estado: "validado" })
      .andWhere("comprobante.fechaPago >= DATE_SUB(NOW(), INTERVAL 12 MONTH)")
      .groupBy("mes")
      .orderBy("mes", "DESC")
      .getRawMany();

    // Comprobantes pendientes de revisión
    const pendientesRevision = await comprobanteRepository.count({
      where: { estado: "pendiente_revision" }
    });

    // Total de ingresos validados
    const totalIngresos = await comprobanteRepository
      .createQueryBuilder("comprobante")
      .select("SUM(comprobante.monto)", "total")
      .where("comprobante.estado = :estado", { estado: "validado" })
      .andWhere(whereCondition)
      .getRawOne();

    const estadisticas = {
      resumen: {
        totalComprobantes,
        pendientesRevision,
        totalIngresos: totalIngresos?.total || 0
      },
      distribucion: {
        porEstado,
        porMetodoPago
      },
      tendencias: {
        ingresosMensuales
      }
    };

    handleSuccess(res, 200, "Estadísticas de pagos obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Eliminar comprobante (Solo Directiva)
export async function eliminarComprobante(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede eliminar comprobantes");
    }

    const comprobante = await comprobanteRepository.findOneBy({ id });
    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    await comprobanteRepository.remove(comprobante);

    handleSuccess(res, 200, "Comprobante eliminado exitosamente");

  } catch (error) {
    console.error("Error eliminando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener comprobante por ID
export async function obtenerComprobantePorId(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const comprobante = await comprobanteRepository.findOne({
      where: { id },
      relations: ["pagador", "planPago", "creadoPor", "validadoPor"]
    });

    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    // Verificar autorización para apoderados
    if (userRole === "apoderado") {
      const puedeVer = comprobante.rutPagador === userRut || 
                      comprobante.creadoPorRut === userRut;
      
      if (!puedeVer) {
        const hijo = await userRepository.findOne({
          where: { rut: comprobante.rutPagador, rutApoderado: userRut }
        });
        if (!hijo) {
          return handleErrorClient(res, 403, "No autorizado");
        }
      }
    }

    handleSuccess(res, 200, "Comprobante obtenido exitosamente", comprobante);

  } catch (error) {
    console.error("Error obteniendo comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
