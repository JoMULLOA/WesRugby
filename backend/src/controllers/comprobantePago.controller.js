"use strict";
import fs from "fs";
import path from "path";
import { randomUUID } from "crypto";
import { In } from "typeorm";
import { AppDataSource } from "../config/configDb.js";
import ComprobantePago from "../entity/comprobantePago.entity.js";
import Estudiante from "../entity/estudiante.entity.js";
import User from "../entity/user.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const comprobanteRepository = AppDataSource.getRepository(ComprobantePago);
const estudianteRepository = AppDataSource.getRepository(Estudiante);
const userRepository = AppDataSource.getRepository(User);

const UPLOADS_ROOT = path.resolve("uploads");
const METODOS_PAGO = ["transferencia", "deposito", "efectivo", "cheque", "tarjeta"];
const ESTADOS_VALIDOS = ["pendiente", "validado", "rechazado", "observado"];
const TIPOS_PAGO = ["mensualidad", "matricula", "uniforme", "evento_especial", "multa", "otro"];

function splitNombreCompleto(nombreCompleto) {
  if (!nombreCompleto) {
    return { nombres: "", apellidos: "" };
  }
  const partes = nombreCompleto.trim().split(/\s+/u);
  if (partes.length === 1) {
    return { nombres: partes[0], apellidos: "" };
  }
  return {
    nombres: partes[0],
    apellidos: partes.slice(1).join(" "),
  };
}

function mapEstudiante(estudiante) {
  if (!estudiante) {
    return null;
  }
  const { nombres, apellidos } = splitNombreCompleto(estudiante.nombre);
  return {
    id: estudiante.rut,
    rut: estudiante.rut,
    nombre: nombres,
    apellidos,
    nombreCompleto: estudiante.nombre,
    curso: estudiante.curso,
    categoria: estudiante.categoria,
    codigoAlumno: estudiante.rut,
    correoApoderadoGenerado: estudiante.correoApoderadoGenerado,
    hermanos: Array.isArray(estudiante.hermanos) ? estudiante.hermanos : [],
    fechaInscripcion: estudiante.createdAt ? estudiante.createdAt.toISOString() : null,
  };
}

function parseDecimal(value) {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  const numberValue = Number(value);
  if (Number.isNaN(numberValue)) {
    return null;
  }
  return Math.round(numberValue * 100) / 100;
}

function parseFecha(value) {
  if (!value) {
    return null;
  }
  const normalized = value.trim();
  const isoCandidate = /^\d{4}-\d{2}-\d{2}$/u.test(normalized)
    ? `${normalized}T00:00:00`
    : normalized;
  const date = new Date(isoCandidate);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return date;
}

function normalizarMes(value) {
  if (!value) {
    return null;
  }
  const trimmed = value.trim();
  return /^\d{4}-(0[1-9]|1[0-2])$/u.test(trimmed) ? trimmed : null;
}

function ensureMetodoPago(metodo) {
  if (!metodo) {
    return null;
  }
  const normalized = metodo.toLowerCase();
  return METODOS_PAGO.includes(normalized) ? normalized : null;
}

function ensureTipoPago(tipo) {
  if (!tipo) {
    return "mensualidad";
  }
  const normalized = tipo.toLowerCase();
  return TIPOS_PAGO.includes(normalized) ? normalized : null;
}

function ensureEstado(estado) {
  if (!estado) {
    return null;
  }
  const normalized = estado.toLowerCase();
  return ESTADOS_VALIDOS.includes(normalized) ? normalized : null;
}

function formatDateOnly(date) {
  if (!date) {
    return null;
  }
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function getRelativeUploadPath(absolutePath) {
  if (!absolutePath) {
    return null;
  }
  const relative = path.relative(UPLOADS_ROOT, absolutePath);
  return relative.split(path.sep).join("/");
}

function cleanupFile(file) {
  if (file?.path && fs.existsSync(file.path)) {
    try {
      fs.unlinkSync(file.path);
    } catch (error) {
      console.warn("No se pudo eliminar el archivo temporal:", error.message);
    }
  }
}

async function generateNumeroComprobante() {
  const prefix = `WR-${new Date().getFullYear()}`;
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const candidate = `${prefix}-${randomUUID().slice(0, 8).toUpperCase()}`;
    const exists = await comprobanteRepository.findOne({
      where: { numeroComprobante: candidate },
    });
    if (!exists) {
      return candidate;
    }
  }
  return `WR-${randomUUID().replace(/-/gu, "").slice(0, 12).toUpperCase()}`;
}

async function getDependientes(apoderadoRut) {
  return estudianteRepository.find({
    where: [
      { rutResponsable: apoderadoRut },
      { rutResponsable2: apoderadoRut },
    ],
    order: { nombre: "ASC" },
  });
}

async function ensureEstudiantePropietario(estudianteRut, apoderadoRut) {
  const estudiante = await estudianteRepository.findOne({
    where: { rut: estudianteRut },
  });
  if (!estudiante) {
    return [null, "Estudiante no encontrado"];
  }
  const autorizado =
    estudiante.rutResponsable === apoderadoRut ||
    estudiante.rutResponsable2 === apoderadoRut;
  if (!autorizado) {
    return [null, "No tienes permisos sobre este estudiante"];
  }
  return [estudiante, null];
}

function buildComprobanteDto(comprobante, estudiantesMap = new Map()) {
  const alumno = estudiantesMap.get(comprobante.estudianteRut) || null;
  return {
    id: comprobante.id,
    numeroComprobante: comprobante.numeroComprobante,
    tipoPago: comprobante.tipoPago,
    metodoPago: comprobante.metodoPago,
    montoTotal: Number(comprobante.montoTotal),
    fechaPago: formatDateOnly(comprobante.fechaPago),
    mesCorrespondiente: comprobante.mesCorrespondiente,
    estado: comprobante.estado,
    bancoOrigen: comprobante.bancoOrigen,
    numeroOperacion: comprobante.numeroOperacion,
    cuentaDestino: comprobante.cuentaDestino,
    observacionesApoderado: comprobante.observacionesApoderado,
    observacionesTesorera: comprobante.observacionesTesorera,
    motivoRechazo: comprobante.motivoRechazo,
    nombreArchivoOriginal: comprobante.nombreArchivoOriginal,
    rutaComprobante: comprobante.rutaComprobante,
    tipoArchivo: comprobante.tipoArchivo,
    tamanoArchivo: comprobante.tamanoArchivo,
    fechaSubida: comprobante.fechaSubida ? comprobante.fechaSubida.toISOString() : null,
    fechaValidacion: comprobante.fechaValidacion
      ? comprobante.fechaValidacion.toISOString()
      : null,
    apoderadoRut: comprobante.apoderadoRut,
    estudianteRut: comprobante.estudianteRut,
    validadoPorRut: comprobante.validadoPorRut,
    subidoPorRut: comprobante.subidoPorRut,
    alumno,
  };
}

export async function crearComprobantePago(req, res) {
  try {
    const userRole = req.user.rol;
    if (!["tesorera", "directiva"].includes(userRole)) {
      return handleErrorClient(
        res,
        403,
        "No autorizado",
        "Solo tesorería o directiva puede crear comprobantes manualmente.",
      );
    }

    const {
      estudianteRut,
      apoderadoRut,
      tipoPago,
      metodoPago,
      montoTotal,
      fechaPago,
      mesCorrespondiente,
      bancoOrigen,
      numeroOperacion,
      cuentaDestino,
      observacionesApoderado,
      estado,
      fechaVencimiento,
    } = req.body;

    if (!estudianteRut) {
      return handleErrorClient(res, 400, "El RUT del estudiante es obligatorio");
    }

    const metodoValido = ensureMetodoPago(metodoPago);
    if (!metodoValido) {
      return handleErrorClient(res, 400, "Método de pago inválido");
    }

    const tipoValido = ensureTipoPago(tipoPago);
    if (!tipoValido) {
      return handleErrorClient(res, 400, "Tipo de pago inválido");
    }

    const monto = parseDecimal(montoTotal);
    if (monto === null || monto <= 0) {
      return handleErrorClient(res, 400, "Monto total inválido");
    }

    const fechaPagoDate = parseFecha(fechaPago);
    if (!fechaPagoDate) {
      return handleErrorClient(res, 400, "Fecha de pago inválida");
    }

    const mesValido = normalizarMes(mesCorrespondiente);
    if (!mesValido) {
      return handleErrorClient(res, 400, "Mes correspondiente inválido");
    }

    const estadoValido = estado ? ensureEstado(estado) : "pendiente";
    if (estado && !estadoValido) {
      return handleErrorClient(res, 400, "Estado inválido");
    }

    const apoderadoObjetivoRut = apoderadoRut || req.user.rut;
    const apoderado = await userRepository.findOne({
      where: { rut: apoderadoObjetivoRut },
    });
    if (!apoderado) {
      return handleErrorClient(res, 404, "Apoderado no encontrado");
    }

    const estudiante = await estudianteRepository.findOne({
      where: { rut: estudianteRut },
    });
    if (!estudiante) {
      return handleErrorClient(res, 404, "Estudiante no encontrado");
    }

    const numeroComprobante = await generateNumeroComprobante();
    const comprobante = comprobanteRepository.create({
      apoderadoRut: apoderadoObjetivoRut,
      estudianteRut,
      numeroComprobante,
      tipoPago: tipoValido,
      metodoPago: metodoValido,
      montoTotal: monto,
      fechaPago: fechaPagoDate,
      fechaVencimiento: fechaVencimiento ? parseFecha(fechaVencimiento) : null,
      mesCorrespondiente: mesValido,
      bancoOrigen,
      numeroOperacion,
      cuentaDestino,
      observacionesApoderado,
      estado: estadoValido,
      subidoPorRut: req.user.rut,
    });

    const guardado = await comprobanteRepository.save(comprobante);
    const estudiantesMap = new Map([[estudianteRut, mapEstudiante(estudiante)]]);
    handleSuccess(
      res,
      201,
      "Comprobante creado exitosamente",
      buildComprobanteDto(guardado, estudiantesMap),
    );
  } catch (error) {
    console.error("Error creando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerComprobantesPago(req, res) {
  try {
    const { rol, rut } = req.user;
    const {
      estado,
      metodoPago,
      apoderadoRut,
      estudianteRut,
      mesCorrespondiente,
      pagina = 1,
      limite = 50,
    } = req.query;

    const filters = {};
    if (rol === "apoderado") {
      filters.apoderadoRut = rut;
    } else if (apoderadoRut) {
      filters.apoderadoRut = apoderadoRut;
    }

    if (estado) {
      const estadoValido = ensureEstado(estado);
      if (!estadoValido) {
        return handleErrorClient(res, 400, "Estado inválido");
      }
      filters.estado = estadoValido;
    }

    if (metodoPago) {
      const metodoValido = ensureMetodoPago(metodoPago);
      if (!metodoValido) {
        return handleErrorClient(res, 400, "Método de pago inválido");
      }
      filters.metodoPago = metodoValido;
    }

    if (estudianteRut) {
      filters.estudianteRut = estudianteRut;
    }

    if (mesCorrespondiente) {
      const mesValido = normalizarMes(mesCorrespondiente);
      if (!mesValido) {
        return handleErrorClient(res, 400, "Mes correspondiente inválido");
      }
      filters.mesCorrespondiente = mesValido;
    }

    const take = Math.min(Number.parseInt(limite, 10) || 50, 100);
    const currentPage = Math.max(Number.parseInt(pagina, 10) || 1, 1);
    const skip = (currentPage - 1) * take;

    const [registros, total] = await comprobanteRepository.findAndCount({
      where: filters,
      order: {
        fechaPago: "DESC",
        createdAt: "DESC",
      },
      take,
      skip,
    });

    const rutsEstudiantes = [
      ...new Set(registros.map((item) => item.estudianteRut).filter(Boolean)),
    ];
    const estudiantes = rutsEstudiantes.length
      ? await estudianteRepository.find({
          where: { rut: In(rutsEstudiantes) },
        })
      : [];
    const estudiantesMap = new Map(
      estudiantes.map((estudiante) => [estudiante.rut, mapEstudiante(estudiante)]),
    );

    const data = registros.map((registro) => buildComprobanteDto(registro, estudiantesMap));

    handleSuccess(res, 200, "Comprobantes obtenidos exitosamente", {
      comprobantes: data,
      paginacion: {
        total,
        pagina: currentPage,
        limite: take,
        totalPaginas: Math.ceil(total / take) || 1,
      },
    });
  } catch (error) {
    console.error("Error obteniendo comprobantes:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerComprobantePorId(req, res) {
  try {
    const { id } = req.params;
    const { rol, rut } = req.user;

    const comprobante = await comprobanteRepository.findOne({ where: { id } });
    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    if (rol === "apoderado" && comprobante.apoderadoRut !== rut) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const estudiante = comprobante.estudianteRut
      ? await estudianteRepository.findOne({
          where: { rut: comprobante.estudianteRut },
        })
      : null;
    const estudiantesMap = estudiante
      ? new Map([[estudiante.rut, mapEstudiante(estudiante)]])
      : new Map();

    handleSuccess(
      res,
      200,
      "Comprobante obtenido exitosamente",
      buildComprobanteDto(comprobante, estudiantesMap),
    );
  } catch (error) {
    console.error("Error obteniendo comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function validarComprobante(req, res) {
  try {
    if (!["tesorera", "directiva"].includes(req.user.rol)) {
      return handleErrorClient(
        res,
        403,
        "No autorizado",
        "Solo tesorería o directiva puede validar comprobantes.",
      );
    }

    const { id } = req.params;
    const { estado, observacionesTesorera, motivoRechazo } = req.body;

    const estadoValido = ensureEstado(estado);
    if (!estadoValido) {
      return handleErrorClient(res, 400, "Estado inválido");
    }

    const comprobante = await comprobanteRepository.findOne({ where: { id } });
    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    comprobante.estado = estadoValido;
    comprobante.observacionesTesorera = observacionesTesorera ?? null;
    comprobante.motivoRechazo = motivoRechazo ?? null;
    comprobante.validadoPorRut = req.user.rut;
    comprobante.fechaValidacion = new Date();

    const actualizado = await comprobanteRepository.save(comprobante);

    const estudiante = actualizado.estudianteRut
      ? await estudianteRepository.findOne({ where: { rut: actualizado.estudianteRut } })
      : null;
    const estudiantesMap = estudiante
      ? new Map([[estudiante.rut, mapEstudiante(estudiante)]])
      : new Map();

    handleSuccess(
      res,
      200,
      "Comprobante validado exitosamente",
      buildComprobanteDto(actualizado, estudiantesMap),
    );
  } catch (error) {
    console.error("Error validando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function actualizarComprobante(req, res) {
  try {
    const { id } = req.params;
    const comprobante = await comprobanteRepository.findOne({ where: { id } });
    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    const { rol, rut } = req.user;

    if (rol === "apoderado" && comprobante.apoderadoRut !== rut) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const payload = req.body;

    if (payload.metodoPago !== undefined) {
      const metodo = ensureMetodoPago(payload.metodoPago);
      if (!metodo) {
        return handleErrorClient(res, 400, "Método de pago inválido");
      }
      comprobante.metodoPago = metodo;
    }

    if (payload.montoTotal !== undefined) {
      const monto = parseDecimal(payload.montoTotal);
      if (monto === null || monto <= 0) {
        return handleErrorClient(res, 400, "Monto total inválido");
      }
      comprobante.montoTotal = monto;
    }

    if (payload.fechaPago !== undefined) {
      const fecha = parseFecha(payload.fechaPago);
      if (!fecha) {
        return handleErrorClient(res, 400, "Fecha de pago inválida");
      }
      comprobante.fechaPago = fecha;
    }

    if (payload.mesCorrespondiente !== undefined) {
      const mesValido = normalizarMes(payload.mesCorrespondiente);
      if (!mesValido) {
        return handleErrorClient(res, 400, "Mes correspondiente inválido");
      }
      comprobante.mesCorrespondiente = mesValido;
    }

    if (payload.bancoOrigen !== undefined) {
      comprobante.bancoOrigen = payload.bancoOrigen || null;
    }

    if (payload.numeroOperacion !== undefined) {
      comprobante.numeroOperacion = payload.numeroOperacion || null;
    }

    if (payload.cuentaDestino !== undefined) {
      comprobante.cuentaDestino = payload.cuentaDestino || null;
    }

    if (payload.observacionesApoderado !== undefined) {
      comprobante.observacionesApoderado = payload.observacionesApoderado || null;
    }

    if (rol !== "apoderado") {
      if (payload.estado !== undefined) {
        const estadoValido = ensureEstado(payload.estado);
        if (!estadoValido) {
          return handleErrorClient(res, 400, "Estado inválido");
        }
        comprobante.estado = estadoValido;
      }

      if (payload.tipoPago !== undefined) {
        const tipoValido = ensureTipoPago(payload.tipoPago);
        if (!tipoValido) {
          return handleErrorClient(res, 400, "Tipo de pago inválido");
        }
        comprobante.tipoPago = tipoValido;
      }

      if (payload.fechaVencimiento !== undefined) {
        comprobante.fechaVencimiento = payload.fechaVencimiento
          ? parseFecha(payload.fechaVencimiento)
          : null;
      }

      if (payload.observacionesTesorera !== undefined) {
        comprobante.observacionesTesorera = payload.observacionesTesorera || null;
      }

      if (payload.motivoRechazo !== undefined) {
        comprobante.motivoRechazo = payload.motivoRechazo || null;
      }

      if (payload.apoderadoRut !== undefined) {
        if (!payload.apoderadoRut) {
          return handleErrorClient(res, 400, "Apoderado inválido");
        }
        const apoderado = await userRepository.findOne({
          where: { rut: payload.apoderadoRut },
        });
        if (!apoderado) {
          return handleErrorClient(res, 404, "Apoderado no encontrado");
        }
        comprobante.apoderadoRut = payload.apoderadoRut;
      }

      if (payload.estudianteRut !== undefined) {
        if (!payload.estudianteRut) {
          return handleErrorClient(res, 400, "Estudiante inválido");
        }
        const estudiante = await estudianteRepository.findOne({
          where: { rut: payload.estudianteRut },
        });
        if (!estudiante) {
          return handleErrorClient(res, 404, "Estudiante no encontrado");
        }
        comprobante.estudianteRut = payload.estudianteRut;
      }
    }

    comprobante.updatedAt = new Date();

    const guardado = await comprobanteRepository.save(comprobante);

    const estudiante = guardado.estudianteRut
      ? await estudianteRepository.findOne({ where: { rut: guardado.estudianteRut } })
      : null;
    const estudiantesMap = estudiante
      ? new Map([[estudiante.rut, mapEstudiante(estudiante)]])
      : new Map();

    handleSuccess(
      res,
      200,
      "Comprobante actualizado exitosamente",
      buildComprobanteDto(guardado, estudiantesMap),
    );
  } catch (error) {
    console.error("Error actualizando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerEstadisticasPagos(req, res) {
  try {
    if (!["tesorera", "directiva"].includes(req.user.rol)) {
      return handleErrorClient(
        res,
        403,
        "No autorizado",
        "Solo tesorería o directiva puede consultar estas estadísticas.",
      );
    }

    const { apoderadoRut, mesCorrespondiente, estado } = req.query;

    const filters = {};
    if (apoderadoRut) {
      filters.apoderadoRut = apoderadoRut;
    }
    if (mesCorrespondiente) {
      const mesValido = normalizarMes(mesCorrespondiente);
      if (!mesValido) {
        return handleErrorClient(res, 400, "Mes correspondiente inválido");
      }
      filters.mesCorrespondiente = mesValido;
    }
    if (estado) {
      const estadoValido = ensureEstado(estado);
      if (!estadoValido) {
        return handleErrorClient(res, 400, "Estado inválido");
      }
      filters.estado = estadoValido;
    }

    const registros = await comprobanteRepository.find({
      where: filters,
    });

    const resumenEstados = new Map();
    const resumenMetodos = new Map();
    const ingresosMensuales = new Map();
    let totalIngresosValidados = 0;

    for (const registro of registros) {
      const estadoActual = registro.estado;
      const metodoActual = registro.metodoPago;
      const mesPago = registro.mesCorrespondiente || formatDateOnly(registro.fechaPago);
      const monto = Number(registro.montoTotal) || 0;

      const estadoStats = resumenEstados.get(estadoActual) || { cantidad: 0, montoTotal: 0 };
      estadoStats.cantidad += 1;
      estadoStats.montoTotal += monto;
      resumenEstados.set(estadoActual, estadoStats);

      if (estadoActual === "validado") {
        const metodoStats = resumenMetodos.get(metodoActual) || { cantidad: 0, montoTotal: 0 };
        metodoStats.cantidad += 1;
        metodoStats.montoTotal += monto;
        resumenMetodos.set(metodoActual, metodoStats);

        if (mesPago) {
          const mesStats = ingresosMensuales.get(mesPago) || { ingresos: 0, cantidad: 0 };
          mesStats.ingresos += monto;
          mesStats.cantidad += 1;
          ingresosMensuales.set(mesPago, mesStats);
        }

        totalIngresosValidados += monto;
      }
    }

    handleSuccess(res, 200, "Estadísticas obtenidas exitosamente", {
      resumen: {
        totalComprobantes: registros.length,
        totalIngresosValidados,
      },
      distribucion: {
        porEstado: Array.from(resumenEstados.entries()).map(([estadoKey, data]) => ({
          estado: estadoKey,
          cantidad: data.cantidad,
          montoTotal: data.montoTotal,
        })),
        porMetodoPago: Array.from(resumenMetodos.entries()).map(([metodoKey, data]) => ({
          metodo: metodoKey,
          cantidad: data.cantidad,
          montoTotal: data.montoTotal,
        })),
      },
      tendencias: {
        ingresosMensuales: Array.from(ingresosMensuales.entries())
          .map(([mes, data]) => ({
            mes,
            ingresos: data.ingresos,
            cantidad: data.cantidad,
          }))
          .sort((a, b) => (a.mes < b.mes ? 1 : -1)),
      },
    });
  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function eliminarComprobante(req, res) {
  try {
    if (req.user.rol !== "directiva") {
      return handleErrorClient(
        res,
        403,
        "No autorizado",
        "Solo directiva puede eliminar comprobantes.",
      );
    }

    const { id } = req.params;
    const comprobante = await comprobanteRepository.findOne({ where: { id } });
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

export async function obtenerInscripcionesApoderado(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const dependientes = await getDependientes(apoderadoRut);
    const payload = dependientes.map((estudiante) => mapEstudiante(estudiante));

    handleSuccess(res, 200, "Inscripciones obtenidas exitosamente", payload);
  } catch (error) {
    console.error("Error obteniendo inscripciones:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function subirVoucherMensualidadApoderado(req, res) {
  const file = req.file;
  try {
    const apoderadoRut = req.user.rut;
    const {
      inscripcionId,
      metodoPago,
      montoTotal,
      fechaPago,
      mesCorrespondiente,
      bancoOrigen,
      numeroOperacion,
      observacionesApoderado,
      aplicarATodos: aplicarATodosRaw,
      estudiantesSeleccionados: seleccionRaw,
    } = req.body;

    if (!inscripcionId) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "Debe seleccionar un alumno");
    }

    const metodoValido = ensureMetodoPago(metodoPago);
    if (!metodoValido) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "Método de pago inválido");
    }

    const monto = parseDecimal(montoTotal);
    if (monto === null || monto <= 0) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "Monto total inválido");
    }

    const fechaPagoDate = parseFecha(fechaPago);
    if (!fechaPagoDate) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "Fecha de pago inválida");
    }

    const mesValido = normalizarMes(mesCorrespondiente);
    if (!mesValido) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "Mes correspondiente inválido");
    }

    const [estudianteSeleccionado, errorEstudiante] = await ensureEstudiantePropietario(
      inscripcionId,
      apoderadoRut,
    );
    if (errorEstudiante) {
      cleanupFile(file);
      return handleErrorClient(res, 403, errorEstudiante);
    }

    const dependientes = await getDependientes(apoderadoRut);
    if (!dependientes.length) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "No se encontraron estudiantes asociados");
    }

    const dependientesMap = new Map(
      dependientes.map((dependiente) => [dependiente.rut, dependiente]),
    );

    const aplicarATodos = [true, "true", 1, "1"].includes(aplicarATodosRaw);

    let seleccionManual = [];
    if (seleccionRaw) {
      try {
        const parsed = typeof seleccionRaw === "string" ? JSON.parse(seleccionRaw) : seleccionRaw;
        if (Array.isArray(parsed)) {
          seleccionManual = parsed
            .map((item) => (typeof item === "string" ? item : String(item)))
            .filter(Boolean);
        }
      } catch (parseError) {
        seleccionManual = String(seleccionRaw)
          .split(",")
          .map((item) => item.trim())
          .filter(Boolean);
      }
    }

    let estudiantesDestino;
    if (aplicarATodos) {
      estudiantesDestino = [...dependientes];
    } else {
      const seleccionUnica = Array.from(new Set(seleccionManual));
      if (!seleccionUnica.length) {
        cleanupFile(file);
        return handleErrorClient(res, 400, "Debe seleccionar al menos un alumno");
      }

      const invalidos = seleccionUnica.filter((rutSeleccionado) => !dependientesMap.has(rutSeleccionado));
      if (invalidos.length) {
        cleanupFile(file);
        return handleErrorClient(
          res,
          400,
          "Se intentó registrar un alumno que no pertenece a su cuenta",
          { alumnosInvalidos: invalidos },
        );
      }

      estudiantesDestino = seleccionUnica
        .map((rutSeleccionado) => dependientesMap.get(rutSeleccionado))
        .filter(Boolean);
    }

    if (!estudiantesDestino?.length) {
      cleanupFile(file);
      return handleErrorClient(res, 400, "No hay alumnos válidos para registrar el pago");
    }

    if (!estudiantesDestino.some((dependiente) => dependiente.rut === estudianteSeleccionado.rut)) {
      estudiantesDestino.unshift(estudianteSeleccionado);
    }

    const fileInfo = file
      ? {
          rutaComprobante: getRelativeUploadPath(file.path),
          nombreArchivoOriginal: file.originalname,
          tipoArchivo: file.mimetype,
          tamanoArchivo: file.size,
        }
      : {};

    const registrosCreados = [];
    for (const dependiente of estudiantesDestino) {
      const numeroComprobante = await generateNumeroComprobante();
      const comprobante = comprobanteRepository.create({
        apoderadoRut,
        estudianteRut: dependiente.rut,
        numeroComprobante,
        tipoPago: "mensualidad",
        metodoPago: metodoValido,
        montoTotal: monto,
        fechaPago: fechaPagoDate,
        mesCorrespondiente: mesValido,
        bancoOrigen,
        numeroOperacion,
        observacionesApoderado,
        estado: "pendiente",
        subidoPorRut: apoderadoRut,
        ...fileInfo,
      });
      const guardado = await comprobanteRepository.save(comprobante);
      registrosCreados.push(guardado);
    }

    const estudiantesMap = new Map(
      estudiantesDestino.map((dependiente) => [dependiente.rut, mapEstudiante(dependiente)]),
    );

    const respuesta = registrosCreados.map((registro) =>
      buildComprobanteDto(registro, estudiantesMap),
    );
    const alumnoPrincipal = dependientesMap.get(inscripcionId) || estudiantesDestino[0];

    handleSuccess(res, 201, "Voucher registrado exitosamente", {
      totalAsignados: respuesta.length,
      comprobantes: respuesta,
      alumnos: Array.from(estudiantesMap.values()),
      alumnoPrincipal: alumnoPrincipal ? mapEstudiante(alumnoPrincipal) : null,
      aplicarATodos,
    });
  } catch (error) {
    cleanupFile(req.file);
    console.error("Error subiendo voucher:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerHistorialApoderado(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const {
      estado,
      mesCorrespondiente,
      pagina = 1,
      limite = 20,
    } = req.query;

    const filters = { apoderadoRut };

    if (estado) {
      const estadoValido = ensureEstado(estado);
      if (!estadoValido) {
        return handleErrorClient(res, 400, "Estado inválido");
      }
      filters.estado = estadoValido;
    }

    if (mesCorrespondiente) {
      const mesValido = normalizarMes(mesCorrespondiente);
      if (!mesValido) {
        return handleErrorClient(res, 400, "Mes correspondiente inválido");
      }
      filters.mesCorrespondiente = mesValido;
    }

    const take = Math.min(Number.parseInt(limite, 10) || 20, 100);
    const currentPage = Math.max(Number.parseInt(pagina, 10) || 1, 1);
    const skip = (currentPage - 1) * take;

    const [registros, total] = await comprobanteRepository.findAndCount({
      where: filters,
      order: {
        fechaPago: "DESC",
        createdAt: "DESC",
      },
      take,
      skip,
    });

    const rutsEstudiantes = [
      ...new Set(registros.map((item) => item.estudianteRut).filter(Boolean)),
    ];
    const estudiantes = rutsEstudiantes.length
      ? await estudianteRepository.find({ where: { rut: In(rutsEstudiantes) } })
      : [];
    const estudiantesMap = new Map(
      estudiantes.map((estudiante) => [estudiante.rut, mapEstudiante(estudiante)]),
    );

    const comprobantes = registros.map((registro) =>
      buildComprobanteDto(registro, estudiantesMap),
    );

    const todosRegistros = await comprobanteRepository.find({
      where: { apoderadoRut },
    });

    const estadisticas = {
      totalPagado: 0,
      totalComprobantes: todosRegistros.length,
      pendientes: 0,
      validados: 0,
      rechazados: 0,
      observados: 0,
    };

    for (const registro of todosRegistros) {
      const monto = Number(registro.montoTotal) || 0;
      if (registro.estado === "validado") {
        estadisticas.validados += 1;
        estadisticas.totalPagado += monto;
      } else if (registro.estado === "pendiente") {
        estadisticas.pendientes += 1;
      } else if (registro.estado === "rechazado") {
        estadisticas.rechazados += 1;
      } else if (registro.estado === "observado") {
        estadisticas.observados += 1;
      }
    }

    handleSuccess(res, 200, "Historial obtenido exitosamente", {
      comprobantes,
      inscripciones: estudiantes.map((estudiante) => mapEstudiante(estudiante)),
      paginacion: {
        total,
        pagina: currentPage,
        limite: take,
        totalPaginas: Math.ceil(total / take) || 1,
      },
      estadisticas,
    });
  } catch (error) {
    console.error("Error obteniendo historial:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function reenviarComprobanteApoderado(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const { id } = req.params;

    const comprobante = await comprobanteRepository.findOne({ where: { id } });
    if (!comprobante || comprobante.apoderadoRut !== apoderadoRut) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    // TODO: Integrar envío real por correo.
    handleSuccess(
      res,
      200,
      "La solicitud de reenvío fue registrada. La funcionalidad de correo se implementará próximamente.",
    );
  } catch (error) {
    console.error("Error reenviando comprobante:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

/**
 * Obtiene los meses no pagados de 2025 para los estudiantes de un apoderado
 * Si tiene múltiples estudiantes, devuelve solo los meses que NINGUNO ha pagado
 * NOTA: Solo incluye marzo-diciembre (enero y febrero son vacaciones)
 */
export async function obtenerMesesNoPagados2025(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const dependientes = await getDependientes(apoderadoRut);

    if (!dependientes || dependientes.length === 0) {
      return handleSuccess(res, 200, "No hay estudiantes asociados", {
        estudiantes: [],
        mesesComunes: [],
      });
    }

    // Solo marzo-diciembre (enero y febrero son vacaciones)
    const MESES_2025 = [
      { value: "2025-03", label: "Marzo 2025", mes: "marzo" },
      { value: "2025-04", label: "Abril 2025", mes: "abril" },
      { value: "2025-05", label: "Mayo 2025", mes: "mayo" },
      { value: "2025-06", label: "Junio 2025", mes: "junio" },
      { value: "2025-07", label: "Julio 2025", mes: "julio" },
      { value: "2025-08", label: "Agosto 2025", mes: "agosto" },
      { value: "2025-09", label: "Septiembre 2025", mes: "septiembre" },
      { value: "2025-10", label: "Octubre 2025", mes: "octubre" },
      { value: "2025-11", label: "Noviembre 2025", mes: "noviembre" },
      { value: "2025-12", label: "Diciembre 2025", mes: "diciembre" },
    ];

    console.log(`🔍 Obteniendo meses no pagados para apoderado: ${apoderadoRut}`);
    console.log(`📊 Total de estudiantes: ${dependientes.length}`);

    // Obtener meses no pagados por cada estudiante
    const estudiantesConMeses = dependientes.map((estudiante) => {
      const mesesNoPagados = [];
      const pagos = estudiante.pagos || {};
      const mesesPagos = pagos.meses || {};

      console.log(`\n👤 Estudiante: ${estudiante.nombre} (${estudiante.rut})`);
      console.log(`   Pagos:`, mesesPagos);

      MESES_2025.forEach((mesInfo) => {
        const estadoPago = mesesPagos[mesInfo.mes];
        // Solo está no pagado si el valor es exactamente "no pagado" (case insensitive)
        // Cualquier otro valor (número, texto, etc.) significa que está pagado
        const estaNoPagado = !estadoPago || 
                            estadoPago.toString().trim().toLowerCase() === "no pagado";
        
        console.log(`   ${mesInfo.mes}: "${estadoPago}" → ${estaNoPagado ? 'NO PAGADO ❌' : 'PAGADO ✅'}`);
        
        if (estaNoPagado) {
          mesesNoPagados.push(mesInfo.value);
        }
      });

      console.log(`   Meses no pagados: ${mesesNoPagados.join(', ') || 'Ninguno'}`);

      return {
        rut: estudiante.rut,
        nombre: estudiante.nombre,
        mesesNoPagados,
      };
    });

    // Si hay múltiples estudiantes, encontrar intersección (meses que NINGUNO ha pagado)
    let mesesComunes;
    if (dependientes.length === 1) {
      mesesComunes = estudiantesConMeses[0].mesesNoPagados;
    } else {
      // Intersección: solo meses que están en TODOS los estudiantes
      mesesComunes = estudiantesConMeses[0].mesesNoPagados.filter((mes) =>
        estudiantesConMeses.every((est) => est.mesesNoPagados.includes(mes))
      );
      console.log(`\n🔄 Intersección (meses que TODOS no han pagado): ${mesesComunes.join(', ') || 'Ninguno'}`);
    }

    // Convertir de vuelta a objetos con label
    const mesesComunesDetalle = MESES_2025.filter((mesInfo) =>
      mesesComunes.includes(mesInfo.value)
    );

    console.log(`\n✅ Meses finales a mostrar en dropdown:`, mesesComunesDetalle);

    handleSuccess(res, 200, "Meses no pagados obtenidos exitosamente", {
      estudiantes: estudiantesConMeses,
      mesesComunes: mesesComunesDetalle,
      totalEstudiantes: dependientes.length,
    });
  } catch (error) {
    console.error("Error obteniendo meses no pagados:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
