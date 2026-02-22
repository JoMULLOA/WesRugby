"use strict";
import { randomUUID } from "crypto";
import { In } from "typeorm";
import { AppDataSource } from "../config/configDb.js";
import ComprobantePago from "../entity/comprobantePago.entity.js";
import Justificante from "../entity/justificante.entity.js";
import Estudiante from "../entity/estudiante.entity.js";
import User from "../entity/user.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { resolveFileUrl, deleteFromS3 } from "../utils/storage.utils.js";

const comprobanteRepository = AppDataSource.getRepository(ComprobantePago);
const justificanteRepository = AppDataSource.getRepository(Justificante);
const estudianteRepository = AppDataSource.getRepository(Estudiante);
const userRepository = AppDataSource.getRepository(User);

const METODOS_PAGO = [
  "transferencia",
  "deposito",
  "efectivo",
  "cheque",
  "tarjeta",
];
const ESTADOS_VALIDOS = ["pendiente", "validado", "rechazado", "observado"];
const TIPOS_PAGO = [
  "mensualidad",
  "matricula",
  "uniforme",
  "evento_especial",
  "multa",
  "otro",
];
// Máximo por definición decimal(10,2) => 8 dígitos enteros + 2 decimales
const MAX_MONTO_TOTAL = 99999999.99;

async function cleanupUploadedAsset(file) {
  if (file?.location) {
    await deleteFromS3(file.location);
  }
}

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
    fechaInscripcion: estudiante.createdAt
      ? estudiante.createdAt.toISOString()
      : null,
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
  const rounded = Math.round(numberValue * 100) / 100;
  if (Math.abs(rounded) > MAX_MONTO_TOTAL) {
    return null; // overflow contra definición columna
  }
  return rounded;
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
  // Formato canonical esperado YYYY-MM
  if (/^\d{4}-(0[1-9]|1[0-2])$/u.test(trimmed)) {
    return trimmed;
  }
  // Intentar parsear formatos tipo "Septiembre 2025" (como en la UI)
  const textoMatch = /^([A-Za-zÁÉÍÓÚáéíóú]+)\s+(\d{4})$/u.exec(trimmed);
  if (textoMatch) {
    const year = textoMatch[2];
    // Normalizar nombre de mes: bajar a lowercase y remover tildes
    const mesNombre = textoMatch[1]
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "");
    const mapaMeses = {
      enero: "01",
      febrero: "02",
      marzo: "03",
      abril: "04",
      mayo: "05",
      junio: "06",
      julio: "07",
      agosto: "08",
      septiembre: "09",
      setiembre: "09", // variante sin 'p'
      octubre: "10",
      noviembre: "11",
      diciembre: "12",
    };
    const mesNumero = mapaMeses[mesNombre];
    if (mesNumero) {
      return `${year}-${mesNumero}`;
    }
  }
  return null;
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

function isComprobanteOwnedByUser(comprobante, user) {
  if (!comprobante || !user) {
    return false;
  }
  const matchesRut =
    comprobante.apoderadoRut && comprobante.apoderadoRut === user.rut;
  const matchesEmail =
    user.email &&
    comprobante.apoderadoEmail &&
    comprobante.apoderadoEmail === user.email;
  return Boolean(matchesRut || matchesEmail);
}

function formatDateOnly(date) {
  if (!date) {
    return null;
  }
  // Si viene ya en formato YYYY-MM-DD (desde Postgres para columnas DATE) retornar directo
  if (typeof date === "string") {
    const trimmed = date.trim();
    if (/^\d{4}-\d{2}-\d{2}$/u.test(trimmed)) {
      return trimmed;
    }
    const parsed = new Date(trimmed);
    if (Number.isNaN(parsed.getTime())) {
      return null;
    }
    date = parsed; // normalizar a Date
  } else if (typeof date === "number") {
    const parsedFromNumber = new Date(date);
    if (Number.isNaN(parsedFromNumber.getTime())) {
      return null;
    }
    date = parsedFromNumber;
  }
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
    return null;
  }
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
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
    rutaComprobante: resolveFileUrl(comprobante.rutaComprobante),
    tipoArchivo: comprobante.tipoArchivo,
    tamanoArchivo: comprobante.tamanoArchivo,
    fechaSubida: comprobante.fechaSubida
      ? comprobante.fechaSubida.toISOString()
      : null,
    fechaValidacion: comprobante.fechaValidacion
      ? comprobante.fechaValidacion.toISOString()
      : null,
    apoderadoRut: comprobante.apoderadoRut,
    apoderadoEmail: comprobante.apoderadoEmail,
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
      return handleErrorClient(
        res,
        400,
        "El RUT del estudiante es obligatorio",
      );
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
    if (monto > MAX_MONTO_TOTAL) {
      return handleErrorClient(
        res,
        400,
        `Monto excede el máximo permitido (${MAX_MONTO_TOTAL}). Ajuste el valor.`,
      );
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
      apoderadoEmail: apoderado.email,
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
    const estudiantesMap = new Map([
      [estudianteRut, mapEstudiante(estudiante)],
    ]);
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

    let whereConditions;
    if (rol === "apoderado") {
      const dependientes = await getDependientes(rut);
      const dependientesRut = dependientes.map((depen) => depen.rut);
      const baseFilter = { ...filters };
      const scopedWhere = [{ ...baseFilter, apoderadoRut: rut }];
      if (req.user.email) {
        scopedWhere.push({ ...baseFilter, apoderadoEmail: req.user.email });
      }
      dependientesRut.forEach((rutEstudiante) => {
        scopedWhere.push({ ...baseFilter, estudianteRut: rutEstudiante });
      });
      console.log("[VOUCHERS][DEBUG] Apoderado solicitando comprobantes", {
        rut,
        email: req.user.email,
        filtros: req.query,
        dependientes: dependientesRut,
        condiciones: scopedWhere,
      });
      whereConditions = scopedWhere;
    } else {
      whereConditions = { ...filters };
      if (apoderadoRut) {
        whereConditions.apoderadoRut = apoderadoRut;
      }
    }

    const take = Math.min(Number.parseInt(limite, 10) || 50, 100);
    const currentPage = Math.max(Number.parseInt(pagina, 10) || 1, 1);
    const skip = (currentPage - 1) * take;

    const [registros, total] = await comprobanteRepository.findAndCount({
      where: whereConditions,
      order: {
        fechaPago: "DESC",
        createdAt: "DESC",
      },
      take,
      skip,
    });

    if (rol === "apoderado") {
      console.log("[VOUCHERS][DEBUG] Resultado para apoderado", {
        rut,
        email: req.user.email,
        total,
        registros: registros.map((r) => ({
          id: r.id,
          estado: r.estado,
          estudianteRut: r.estudianteRut,
          apoderadoRut: r.apoderadoRut,
          apoderadoEmail: r.apoderadoEmail,
        })),
      });
    }

    const rutsEstudiantes = [
      ...new Set(registros.map((item) => item.estudianteRut).filter(Boolean)),
    ];
    const estudiantes = rutsEstudiantes.length
      ? await estudianteRepository.find({
          where: { rut: In(rutsEstudiantes) },
        })
      : [];
    const estudiantesMap = new Map(
      estudiantes.map((estudiante) => [
        estudiante.rut,
        mapEstudiante(estudiante),
      ]),
    );

    const data = registros.map((registro) =>
      buildComprobanteDto(registro, estudiantesMap),
    );

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
    const { rol } = req.user;

    const comprobante = await comprobanteRepository.findOne({ where: { id } });
    if (!comprobante) {
      return handleErrorClient(res, 404, "Comprobante no encontrado");
    }

    if (
      rol === "apoderado" &&
      !isComprobanteOwnedByUser(comprobante, req.user)
    ) {
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

    // Si se aprobó (validado), actualizar pagos de todos los estudiantes
    if (estadoValido === "validado") {
      try {
        console.log(
          `💰 Procesando aprobación de comprobante ${actualizado.numeroComprobante}`,
        );

        // Función para extraer año y mes de formato "YYYY-MM" o "Nombre Año"
        const extraerAnioYMes = (mesValue) => {
          // Formato YYYY-MM (ej: "2026-03")
          const matchYYYYMM = mesValue.match(/^(\d{4})-(\d{2})$/);
          if (matchYYYYMM) {
            const anio = parseInt(matchYYYYMM[1]);
            const mesNum = parseInt(matchYYYYMM[2]);
            const nombresMeses = [
              "enero",
              "febrero",
              "marzo",
              "abril",
              "mayo",
              "junio",
              "julio",
              "agosto",
              "septiembre",
              "octubre",
              "noviembre",
              "diciembre",
            ];
            return { anio, nombreMes: nombresMeses[mesNum - 1] };
          }

          // Formato "Nombre Año" (ej: "Marzo 2026")
          const mesesNombres = {
            enero: "enero",
            febrero: "febrero",
            marzo: "marzo",
            abril: "abril",
            mayo: "mayo",
            junio: "junio",
            julio: "julio",
            agosto: "agosto",
            septiembre: "septiembre",
            octubre: "octubre",
            noviembre: "noviembre",
            diciembre: "diciembre",
          };

          const mesValueLower = mesValue.toLowerCase();
          for (const [nombre, key] of Object.entries(mesesNombres)) {
            if (mesValueLower.includes(nombre)) {
              // Extraer año del formato "Marzo 2026"
              const matchAnio = mesValue.match(/\d{4}/);
              const anio = matchAnio ? parseInt(matchAnio[0]) : 2025;
              return { anio, nombreMes: key };
            }
          }

          return null;
        };

        // Si hay detallesPago (pago agrupado), procesar cada estudiante
        if (
          actualizado.detallesPago &&
          typeof actualizado.detallesPago === "object"
        ) {
          console.log(
            `📦 Pago agrupado detectado con ${Object.keys(actualizado.detallesPago).length} estudiantes`,
          );

          for (const [estudianteRut, detalles] of Object.entries(
            actualizado.detallesPago,
          )) {
            const estudiante = await estudianteRepository.findOne({
              where: { rut: estudianteRut },
            });

            if (!estudiante) {
              console.warn(`⚠️ Estudiante no encontrado: ${estudianteRut}`);
              continue;
            }

            // Inicializar pagos si no existe
            if (!estudiante.pagos) {
              estudiante.pagos = {};
            }
            if (!estudiante.pagosPorAnio) {
              estudiante.pagosPorAnio = {};
            }

            if (actualizado.tipoPago === "mensualidad") {
              const meses = detalles.meses || [];
              const montoTotalEstudiante = detalles.monto || 0;

              // Dividir el monto total entre la cantidad de meses
              const cantidadMeses = meses.length;
              const montoPorMes =
                cantidadMeses > 0
                  ? montoTotalEstudiante / cantidadMeses
                  : montoTotalEstudiante;

              console.log(
                `   Estudiante ${estudianteRut}: ${cantidadMeses} meses, monto total $${montoTotalEstudiante}, por mes $${montoPorMes.toFixed(0)}`,
              );

              for (const mesValue of meses) {
                const resultado = extraerAnioYMes(mesValue);

                if (resultado) {
                  const { anio, nombreMes } = resultado;

                  // Inicializar estructura por año si no existe
                  if (!estudiante.pagosPorAnio[anio]) {
                    estudiante.pagosPorAnio[anio] = { meses: {} };
                  }
                  if (!estudiante.pagosPorAnio[anio].meses) {
                    estudiante.pagosPorAnio[anio].meses = {};
                  }

                  estudiante.pagosPorAnio[anio].meses[nombreMes] =
                    Math.round(montoPorMes).toString();
                  console.log(
                    `      ✓ ${nombreMes} ${anio}: $${Math.round(montoPorMes)}`,
                  );

                  // También guardar en estructura legacy para 2025
                  if (anio === 2025) {
                    if (!estudiante.pagos.meses) {
                      estudiante.pagos.meses = {};
                    }
                    estudiante.pagos.meses[nombreMes] =
                      Math.round(montoPorMes).toString();
                  }
                } else {
                  console.warn(`⚠️ No se pudo mapear mes: ${mesValue}`);
                }
              }

              await estudianteRepository.save(estudiante);
            } else if (actualizado.tipoPago === "matricula") {
              const montoPorEstudiante = detalles.monto || 0;

              // Extraer año del comprobante (debería venir en anioMatricula)
              const anio = actualizado.anioMatricula || 2025;

              if (!estudiante.pagosPorAnio[anio]) {
                estudiante.pagosPorAnio[anio] = {};
              }
              estudiante.pagosPorAnio[anio].matricula =
                montoPorEstudiante.toString();

              // También guardar en estructura legacy para 2025
              if (anio === 2025) {
                estudiante.pagos.matricula = montoPorEstudiante.toString();
              }

              await estudianteRepository.save(estudiante);
              console.log(
                `✅ ${estudianteRut}: Matrícula ${anio} = ${montoPorEstudiante}`,
              );
            }
          }
        } else {
          // Pago simple (un estudiante, un mes) - lógica original
          console.log(`📦 Pago simple: ${actualizado.estudianteRut}`);

          const estudiante = await estudianteRepository.findOne({
            where: { rut: actualizado.estudianteRut },
          });

          if (estudiante) {
            if (!estudiante.pagos) {
              estudiante.pagos = {};
            }
            if (!estudiante.pagosPorAnio) {
              estudiante.pagosPorAnio = {};
            }

            if (actualizado.tipoPago === "mensualidad") {
              const resultado = extraerAnioYMes(actualizado.mesCorrespondiente);

              if (resultado) {
                const { anio, nombreMes } = resultado;

                // Inicializar estructura por año si no existe
                if (!estudiante.pagosPorAnio[anio]) {
                  estudiante.pagosPorAnio[anio] = { meses: {} };
                }
                if (!estudiante.pagosPorAnio[anio].meses) {
                  estudiante.pagosPorAnio[anio].meses = {};
                }

                estudiante.pagosPorAnio[anio].meses[nombreMes] =
                  actualizado.montoTotal.toString();

                // También guardar en estructura legacy para 2025
                if (anio === 2025) {
                  if (!estudiante.pagos.meses) {
                    estudiante.pagos.meses = {};
                  }
                  estudiante.pagos.meses[nombreMes] =
                    actualizado.montoTotal.toString();
                }

                await estudianteRepository.save(estudiante);
                console.log(
                  `✅ Mensualidad registrada: ${nombreMes} ${anio} = ${actualizado.montoTotal}`,
                );
              } else {
                console.warn(
                  `⚠️ Mes no reconocido: ${actualizado.mesCorrespondiente}`,
                );
              }
            } else if (actualizado.tipoPago === "matricula") {
              const anio = actualizado.anioMatricula || 2025;

              if (!estudiante.pagosPorAnio[anio]) {
                estudiante.pagosPorAnio[anio] = {};
              }
              estudiante.pagosPorAnio[anio].matricula =
                actualizado.montoTotal.toString();

              // También guardar en estructura legacy para 2025
              if (anio === 2025) {
                estudiante.pagos.matricula = actualizado.montoTotal.toString();
              }

              await estudianteRepository.save(estudiante);
              console.log(
                `✅ Matrícula ${anio} registrada: ${actualizado.montoTotal}`,
              );
            }
          } else {
            console.warn(
              `⚠️ Estudiante no encontrado: ${actualizado.estudianteRut}`,
            );
          }
        }
      } catch (pagoError) {
        console.error("❌ Error actualizando pagos de estudiantes:", pagoError);
        // No fallar la aprobación del comprobante por error en actualización de pagos
      }
    }

    const estudiante = actualizado.estudianteRut
      ? await estudianteRepository.findOne({
          where: { rut: actualizado.estudianteRut },
        })
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

    const { rol } = req.user;

    if (
      rol === "apoderado" &&
      !isComprobanteOwnedByUser(comprobante, req.user)
    ) {
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
      if (monto > MAX_MONTO_TOTAL) {
        return handleErrorClient(
          res,
          400,
          `Monto excede el máximo permitido (${MAX_MONTO_TOTAL}).`,
        );
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
      comprobante.observacionesApoderado =
        payload.observacionesApoderado || null;
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
        comprobante.observacionesTesorera =
          payload.observacionesTesorera || null;
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
        comprobante.apoderadoEmail = apoderado.email;
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
      ? await estudianteRepository.findOne({
          where: { rut: guardado.estudianteRut },
        })
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
      const mesPago =
        registro.mesCorrespondiente || formatDateOnly(registro.fechaPago);
      const monto = Number(registro.montoTotal) || 0;

      const estadoStats = resumenEstados.get(estadoActual) || {
        cantidad: 0,
        montoTotal: 0,
      };
      estadoStats.cantidad += 1;
      estadoStats.montoTotal += monto;
      resumenEstados.set(estadoActual, estadoStats);

      if (estadoActual === "validado") {
        const metodoStats = resumenMetodos.get(metodoActual) || {
          cantidad: 0,
          montoTotal: 0,
        };
        metodoStats.cantidad += 1;
        metodoStats.montoTotal += monto;
        resumenMetodos.set(metodoActual, metodoStats);

        if (mesPago) {
          const mesStats = ingresosMensuales.get(mesPago) || {
            ingresos: 0,
            cantidad: 0,
          };
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
        porEstado: Array.from(resumenEstados.entries()).map(
          ([estadoKey, data]) => ({
            estado: estadoKey,
            cantidad: data.cantidad,
            montoTotal: data.montoTotal,
          }),
        ),
        porMetodoPago: Array.from(resumenMetodos.entries()).map(
          ([metodoKey, data]) => ({
            metodo: metodoKey,
            cantidad: data.cantidad,
            montoTotal: data.montoTotal,
          }),
        ),
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

    await deleteFromS3(comprobante.rutaComprobante);

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
      detallesPago: detallesPagoRaw,
    } = req.body;

    // Parsear detallesPago si viene del frontend (pago agrupado)
    let detallesPagoRecibido = null;
    if (detallesPagoRaw) {
      try {
        detallesPagoRecibido =
          typeof detallesPagoRaw === "string"
            ? JSON.parse(detallesPagoRaw)
            : detallesPagoRaw;
        console.log(
          "📦 detallesPago recibido desde frontend:",
          JSON.stringify(detallesPagoRecibido, null, 2),
        );
      } catch (parseError) {
        console.error("❌ Error parseando detallesPago:", parseError);
        await cleanupUploadedAsset(file);
        return handleErrorClient(res, 400, "Formato de detallesPago inválido");
      }
    }

    if (!inscripcionId) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Debe seleccionar un alumno");
    }

    const metodoValido = ensureMetodoPago(metodoPago);
    if (!metodoValido) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Método de pago inválido");
    }

    const monto = parseDecimal(montoTotal);
    if (monto === null || monto <= 0) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Monto total inválido");
    }
    if (monto > MAX_MONTO_TOTAL) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Monto excede el máximo permitido.");
    }

    const fechaPagoDate = parseFecha(fechaPago);
    if (!fechaPagoDate) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Fecha de pago inválida");
    }

    // Si viene detallesPago (pago agrupado), el mes puede ser "Multiple" o estar vacío
    // Los meses reales estarán en detallesPago
    let mesValido = null;
    if (!detallesPagoRecibido) {
      // Solo validar mes si NO es pago agrupado
      mesValido = normalizarMes(mesCorrespondiente);
      if (!mesValido) {
        await cleanupUploadedAsset(file);
        return handleErrorClient(res, 400, "Mes correspondiente inválido");
      }
    } else {
      // Para pago agrupado, usar "Multiple" como referencia
      mesValido = "Multiple";
    }

    const [estudianteSeleccionado, errorEstudiante] =
      await ensureEstudiantePropietario(inscripcionId, apoderadoRut);
    if (errorEstudiante) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 403, errorEstudiante);
    }

    const dependientes = await getDependientes(apoderadoRut);
    if (!dependientes.length) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(
        res,
        400,
        "No se encontraron estudiantes asociados",
      );
    }

    const dependientesMap = new Map(
      dependientes.map((dependiente) => [dependiente.rut, dependiente]),
    );

    const aplicarATodos = [true, "true", 1, "1"].includes(aplicarATodosRaw);

    let seleccionManual = [];
    if (seleccionRaw) {
      try {
        const parsed =
          typeof seleccionRaw === "string"
            ? JSON.parse(seleccionRaw)
            : seleccionRaw;
        if (Array.isArray(parsed)) {
          seleccionManual = parsed
            .map((item) => (typeof item === "string" ? item : String(item)))
            .filter(Boolean);
        }
      } catch {
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
        await cleanupUploadedAsset(file);
        return handleErrorClient(
          res,
          400,
          "Debe seleccionar al menos un alumno",
        );
      }

      const invalidos = seleccionUnica.filter(
        (rutSeleccionado) => !dependientesMap.has(rutSeleccionado),
      );
      if (invalidos.length) {
        await cleanupUploadedAsset(file);
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
      await cleanupUploadedAsset(file);
      return handleErrorClient(
        res,
        400,
        "No hay alumnos válidos para registrar el pago",
      );
    }

    if (
      !estudiantesDestino.some(
        (dependiente) => dependiente.rut === estudianteSeleccionado.rut,
      )
    ) {
      estudiantesDestino.unshift(estudianteSeleccionado);
    }

    const fileInfo = file
      ? {
          rutaComprobante:
            file.location ||
            file.key ||
            (file.filename ? `uploads/${file.filename}` : null) ||
            file.path,
          nombreArchivoOriginal: file.originalname,
          tipoArchivo: file.mimetype,
          tamanoArchivo: file.size,
        }
      : {};

    // Crear UN SOLO comprobante agrupado con todos los estudiantes
    const numeroComprobante = await generateNumeroComprobante();

    // Usar detallesPago del frontend si está disponible, sino construirlo
    let detallesPago;
    let estudiantesRuts;
    let mesesCorrespondientes;

    if (detallesPagoRecibido) {
      // Pago agrupado desde frontend (múltiples estudiantes y/o meses)
      detallesPago = detallesPagoRecibido;
      estudiantesRuts = Object.keys(detallesPago);

      // Extraer todos los meses únicos del detallesPago
      const mesesSet = new Set();
      Object.values(detallesPago).forEach((detalle) => {
        if (detalle.meses && Array.isArray(detalle.meses)) {
          detalle.meses.forEach((mes) => mesesSet.add(mes));
        }
      });
      mesesCorrespondientes = Array.from(mesesSet);

      console.log("✅ Usando detallesPago recibido desde frontend");
      console.log(`   Estudiantes: ${estudiantesRuts.length}`);
      console.log(`   Meses únicos: ${mesesCorrespondientes.join(", ")}`);
    } else {
      // Pago simple (construcción legacy)
      detallesPago = {};
      estudiantesRuts = [];
      mesesCorrespondientes = [mesValido];

      const montoIndividual =
        estudiantesDestino.length > 0
          ? monto / estudiantesDestino.length
          : monto;

      estudiantesDestino.forEach((dependiente) => {
        estudiantesRuts.push(dependiente.rut);
        detallesPago[dependiente.rut] = {
          meses: [mesValido],
          monto: montoIndividual,
        };
      });

      console.log("✅ Construyendo detallesPago desde lógica legacy");
    }

    const comprobante = comprobanteRepository.create({
      apoderadoRut,
      apoderadoEmail: req.user.email,
      estudianteRut: estudiantesDestino[0].rut, // Primer estudiante como referencia
      numeroComprobante,
      tipoPago: "mensualidad",
      metodoPago: metodoValido,
      montoTotal: monto,
      fechaPago: fechaPagoDate,
      mesCorrespondiente: mesValido, // Primer mes como referencia
      bancoOrigen,
      numeroOperacion,
      observacionesApoderado,
      estado: "pendiente",
      subidoPorRut: apoderadoRut,
      // Nuevos campos para pago agrupado
      estudiantesRuts,
      mesesCorrespondientes,
      detallesPago,
      ...fileInfo,
    });

    const guardado = await comprobanteRepository.save(comprobante);
    console.log(`✅ Comprobante agrupado guardado: ${numeroComprobante}`);
    console.log(
      `   Total estudiantes: ${estudiantesRuts.length}, Total meses: ${mesesCorrespondientes.length}`,
    );
    console.log(`   Monto total: $${monto}`);

    const estudiantesMap = new Map(
      estudiantesDestino.map((dependiente) => [
        dependiente.rut,
        mapEstudiante(dependiente),
      ]),
    );

    const alumnoPrincipal =
      dependientesMap.get(inscripcionId) || estudiantesDestino[0];

    handleSuccess(res, 201, "Voucher registrado exitosamente", {
      comprobante: buildComprobanteDto(guardado, estudiantesMap),
      alumnos: Array.from(estudiantesMap.values()),
      alumnoPrincipal: alumnoPrincipal ? mapEstudiante(alumnoPrincipal) : null,
      aplicarATodos,
    });
  } catch (error) {
    await cleanupUploadedAsset(req.file);
    console.error("Error subiendo voucher:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function subirVoucherMatriculaApoderado(req, res) {
  const file = req.file;
  try {
    const apoderadoRut = req.user.rut;
    const {
      inscripcionId,
      metodoPago,
      montoTotal,
      fechaPago,
      anioMatricula,
      bancoOrigen,
      numeroOperacion,
      observacionesApoderado,
    } = req.body;

    if (!inscripcionId) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Debe seleccionar un alumno");
    }

    const metodoValido = ensureMetodoPago(metodoPago);
    if (!metodoValido) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Método de pago inválido");
    }

    const monto = parseDecimal(montoTotal);
    if (monto === null || monto <= 0) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Monto total inválido");
    }
    if (monto > MAX_MONTO_TOTAL) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Monto excede el máximo permitido.");
    }

    const fechaPagoDate = parseFecha(fechaPago);
    if (!fechaPagoDate) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 400, "Fecha de pago inválida");
    }

    const anio = parseInt(String(anioMatricula), 10);
    // Permitir años desde 2025 (datos históricos del Excel) hasta 2030
    if (!anio || anio < 2025 || anio > 2030) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(
        res,
        400,
        "Año de matrícula inválido (debe estar entre 2025 y 2030)",
      );
    }

    const [estudianteSeleccionado, errorEstudiante] =
      await ensureEstudiantePropietario(inscripcionId, apoderadoRut);
    if (errorEstudiante) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(res, 403, errorEstudiante);
    }

    // Verificar si ya existe matrícula pagada (validada) para ese año
    const existente = await comprobanteRepository.findOne({
      where: {
        estudianteRut: estudianteSeleccionado.rut,
        tipoPago: "matricula",
        anioMatricula: anio,
        estado: In(["pendiente", "validado", "observado"]),
      },
    });
    if (existente) {
      await cleanupUploadedAsset(file);
      return handleErrorClient(
        res,
        409,
        "Ya existe un comprobante de matrícula para ese año",
      );
    }

    const fileInfo = file
      ? {
          rutaComprobante:
            file.location ||
            file.key ||
            (file.filename ? `uploads/${file.filename}` : null) ||
            file.path,
          nombreArchivoOriginal: file.originalname,
          tipoArchivo: file.mimetype,
          tamanoArchivo: file.size,
        }
      : {};

    const numeroComprobante = await generateNumeroComprobante();
    const comprobante = comprobanteRepository.create({
      apoderadoRut,
      apoderadoEmail: req.user.email,
      estudianteRut: estudianteSeleccionado.rut,
      numeroComprobante,
      tipoPago: "matricula",
      metodoPago: metodoValido,
      montoTotal: monto,
      fechaPago: fechaPagoDate,
      mesCorrespondiente: `${anio}-01`,
      anioMatricula: anio,
      bancoOrigen,
      numeroOperacion,
      observacionesApoderado,
      estado: "pendiente",
      subidoPorRut: apoderadoRut,
      ...fileInfo,
    });
    const guardado = await comprobanteRepository.save(comprobante);

    const respuesta = buildComprobanteDto(
      guardado,
      new Map([
        [estudianteSeleccionado.rut, mapEstudiante(estudianteSeleccionado)],
      ]),
    );

    handleSuccess(
      res,
      201,
      "Voucher matrícula registrado exitosamente",
      respuesta,
    );
  } catch (error) {
    await cleanupUploadedAsset(req.file);
    console.error("Error subiendo voucher matrícula:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function obtenerHistorialApoderado(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const {
      estado,
      mesCorrespondiente,
      metodoPago,
      pagina = 1,
      limite = 20,
    } = req.query;

    const dependientes = await getDependientes(apoderadoRut);
    const dependientesRut = dependientes.map((estudiante) => estudiante.rut);

    const take = Math.min(Number.parseInt(limite, 10) || 20, 100);
    const currentPage = Math.max(Number.parseInt(pagina, 10) || 1, 1);
    const skip = (currentPage - 1) * take;

    let estadoValido = null;
    if (estado && estado.toLowerCase() !== "todos") {
      estadoValido = ensureEstado(estado);
      if (!estadoValido) {
        return handleErrorClient(res, 400, "Estado inválido");
      }
    }

    let metodoValido = null;
    if (metodoPago) {
      metodoValido = ensureMetodoPago(metodoPago);
      if (!metodoValido) {
        return handleErrorClient(res, 400, "Método de pago inválido");
      }
    }

    let mesValido = null;
    if (mesCorrespondiente) {
      mesValido = normalizarMes(mesCorrespondiente);
      if (!mesValido) {
        return handleErrorClient(res, 400, "Mes correspondiente inválido");
      }
    }

    // SOLO vouchers de los hijos del apoderado
    if (!dependientesRut.length) {
      return handleSuccess(res, 200, "No tiene hijos registrados", {
        comprobantes: [],
        inscripciones: [],
        paginacion: {
          total: 0,
          pagina: currentPage,
          limite: take,
          totalPaginas: 1,
        },
        estadisticas: {
          totalPagado: 0,
          totalComprobantes: 0,
          pendientes: 0,
          validados: 0,
          rechazados: 0,
          observados: 0,
        },
      });
    }

    const filters = { estudianteRut: In(dependientesRut) };
    if (estadoValido) filters.estado = estadoValido;
    if (metodoValido) filters.metodoPago = metodoValido;
    if (mesValido) filters.mesCorrespondiente = mesValido;

    const [registros, total] = await comprobanteRepository.findAndCount({
      where: filters,
      order: { fechaPago: "DESC", createdAt: "DESC" },
      take,
      skip,
    });

    const estudiantesMap = new Map(
      dependientes.map((estudiante) => [
        estudiante.rut,
        mapEstudiante(estudiante),
      ]),
    );
    const comprobantes = registros.map((registro) =>
      buildComprobanteDto(registro, estudiantesMap),
    );

    // Estadísticas por estado
    const countByEstado = {
      pendientes: 0,
      validados: 0,
      rechazados: 0,
      observados: 0,
    };
    let totalPagado = 0;
    for (const registro of registros) {
      if (registro.estado === "validado") {
        countByEstado.validados++;
        totalPagado += Number(registro.montoTotal) || 0;
      } else if (registro.estado === "pendiente") countByEstado.pendientes++;
      else if (registro.estado === "rechazado") countByEstado.rechazados++;
      else if (registro.estado === "observado") countByEstado.observados++;
    }

    handleSuccess(res, 200, "Historial obtenido exitosamente", {
      comprobantes,
      inscripciones: dependientes.map((estudiante) =>
        mapEstudiante(estudiante),
      ),
      paginacion: {
        total,
        pagina: currentPage,
        limite: take,
        totalPaginas: Math.max(Math.ceil(total / take), 1),
      },
      estadisticas: {
        totalPagado,
        totalComprobantes: total,
        pendientes: countByEstado.pendientes,
        validados: countByEstado.validados,
        rechazados: countByEstado.rechazados,
        observados: countByEstado.observados,
      },
    });
  } catch (error) {
    console.error("Error obteniendo historial:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

export async function reenviarComprobanteApoderado(req, res) {
  try {
    const { id } = req.params;

    const comprobante = await comprobanteRepository.findOne({ where: { id } });
    if (!comprobante || !isComprobanteOwnedByUser(comprobante, req.user)) {
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
 * Obtiene TODOS los meses no pagados de TODOS los años (2025-2030) para los estudiantes de un apoderado
 * Si tiene múltiples estudiantes, devuelve solo los meses que NINGUNO ha pagado
 * NOTA: Solo incluye marzo-diciembre (enero y febrero son vacaciones)
 */
export async function obtenerMesesNoPagados2025(req, res) {
  try {
    const apoderadoRut = req.user.rut;
    const { rutEstudiantes, anio } = req.query;

    // Si se especifica un año, devolver solo ese año (compatibilidad)
    // Si no, devolver TODOS los años con meses pendientes
    const consultarTodosLosAnios = !anio;
    const aniosAConsultar = consultarTodosLosAnios
      ? [2025, 2026, 2027, 2028, 2029, 2030]
      : [parseInt(anio, 10)];

    if (
      !consultarTodosLosAnios &&
      (aniosAConsultar[0] < 2025 || aniosAConsultar[0] > 2030)
    ) {
      return handleErrorClient(res, 400, "Año debe estar entre 2025 y 2030");
    }

    let dependientes = await getDependientes(apoderadoRut);

    if (!dependientes || dependientes.length === 0) {
      return handleSuccess(res, 200, "No hay estudiantes asociados", {
        estudiantes: [],
        mesesComunes: [],
        anios: aniosAConsultar,
      });
    }

    // Si se especificaron RUTs, filtrar solo esos estudiantes
    if (rutEstudiantes) {
      const rutsArray = rutEstudiantes.split(",").map((r) => r.trim());
      console.log(`🔍 Filtrando por RUTs específicos: ${rutsArray.join(", ")}`);
      dependientes = dependientes.filter((d) => rutsArray.includes(d.rut));

      if (dependientes.length === 0) {
        return handleSuccess(
          res,
          200,
          "No se encontraron estudiantes con los RUTs especificados",
          {
            estudiantes: [],
            mesesComunes: [],
            anios: aniosAConsultar,
          },
        );
      }
    }

    // Definición de meses (marzo-diciembre)
    const MESES_NOMBRES = [
      { num: "03", nombre: "Marzo", key: "marzo" },
      { num: "04", nombre: "Abril", key: "abril" },
      { num: "05", nombre: "Mayo", key: "mayo" },
      { num: "06", nombre: "Junio", key: "junio" },
      { num: "07", nombre: "Julio", key: "julio" },
      { num: "08", nombre: "Agosto", key: "agosto" },
      { num: "09", nombre: "Septiembre", key: "septiembre" },
      { num: "10", nombre: "Octubre", key: "octubre" },
      { num: "11", nombre: "Noviembre", key: "noviembre" },
      { num: "12", nombre: "Diciembre", key: "diciembre" },
    ];

    console.log(
      `🔍 Obteniendo meses no pagados para apoderado: ${apoderadoRut}`,
    );
    console.log(`📅 Años a consultar: ${aniosAConsultar.join(", ")}`);
    console.log(`📊 Total de estudiantes: ${dependientes.length}`);

    // Obtener justificantes aprobados
    const rutsDependientes = dependientes.map((d) => d.rut);
    const justificantesAprobados = await justificanteRepository.find({
      where: {
        estado: "aprobado",
        estudianteRut: In(rutsDependientes),
      },
    });

    // Agrupar meses de exención por estudiante (para todos los años)
    const mesesExencionPorRut = new Map();
    justificantesAprobados.forEach((j) => {
      if (Array.isArray(j.mesesExencion)) {
        const actuales = mesesExencionPorRut.get(j.estudianteRut) || new Set();
        j.mesesExencion.forEach((m) => {
          // Considerar formato canonical YYYY-MM de cualquier año
          if (
            typeof m === "string" &&
            /^(202[5-9]|2030)-(0[1-9]|1[0-2])$/u.test(m)
          ) {
            actuales.add(m);
          }
        });
        mesesExencionPorRut.set(j.estudianteRut, actuales);
      }
    });

    // Generar todos los meses de todos los años
    const todosMesesTodosAnios = [];
    aniosAConsultar.forEach((anio) => {
      MESES_NOMBRES.forEach((m) => {
        todosMesesTodosAnios.push({
          value: `${anio}-${m.num}`,
          label: `${m.nombre} ${anio}`,
          mes: m.key,
          anio: anio,
        });
      });
    });

    // Obtener meses no pagados por cada estudiante para TODOS los años
    const estudiantesConMeses = dependientes.map((estudiante) => {
      const mesesNoPagados = [];
      const mesesExentos = [];
      const pagos = estudiante.pagos || {};
      const mesesPagos = pagos.meses || {};

      console.log(`\n👤 Estudiante: ${estudiante.nombre} (${estudiante.rut})`);
      console.log(`   Pagos en base de datos:`, mesesPagos);

      const mesesExentosSet =
        mesesExencionPorRut.get(estudiante.rut) || new Set();

      todosMesesTodosAnios.forEach((mesInfo) => {
        // Si el mes está marcado como exento por justificante aprobado
        if (mesesExentosSet.has(mesInfo.value)) {
          mesesExentos.push(mesInfo.value);
          console.log(`   ${mesInfo.label}: EXENTO (justificante aprobado) 🟡`);
          return;
        }

        // IMPORTANTE: Los pagos del Excel (mesesPagos) solo aplican al año 2025
        // Para años 2026-2030, todos los meses están disponibles (no pagados aún)
        let estaNoPagado;

        if (mesInfo.anio === 2025) {
          // Para 2025: verificar contra los pagos del Excel
          const estadoPago = mesesPagos[mesInfo.mes];
          // Solo está no pagado si el valor es exactamente "no pagado" (case insensitive)
          // Cualquier otro valor (número, texto, etc.) significa que está pagado
          estaNoPagado =
            !estadoPago ||
            estadoPago.toString().trim().toLowerCase() === "no pagado";
        } else {
          // Para 2026-2030: todos los meses están disponibles (no hay pagos registrados)
          estaNoPagado = true;
        }

        if (estaNoPagado) {
          mesesNoPagados.push(mesInfo.value);
          console.log(`   ${mesInfo.label}: NO PAGADO ❌`);
        } else {
          console.log(
            `   ${mesInfo.label}: PAGADO ✅ (${mesesPagos[mesInfo.mes]})`,
          );
        }
      });

      console.log(`   Total meses no pagados: ${mesesNoPagados.length}`);

      return {
        rut: estudiante.rut,
        nombre: estudiante.nombre,
        mesesNoPagados,
        mesesExentos,
      };
    });

    // Si hay múltiples estudiantes, encontrar intersección (meses que NINGUNO ha pagado)
    let mesesComunes;
    if (dependientes.length === 1) {
      mesesComunes = estudiantesConMeses[0].mesesNoPagados;
    } else {
      // Intersección: solo meses que están en TODOS los estudiantes
      mesesComunes = estudiantesConMeses[0].mesesNoPagados.filter((mes) =>
        estudiantesConMeses.every((est) => est.mesesNoPagados.includes(mes)),
      );
      console.log(
        `\n🔄 Intersección (meses que TODOS no han pagado): ${mesesComunes.length} meses`,
      );
    }

    // Convertir de vuelta a objetos con label
    const mesesComunesDetalle = todosMesesTodosAnios.filter((mesInfo) =>
      mesesComunes.includes(mesInfo.value),
    );

    console.log(
      `\n✅ Total de meses disponibles para pagar: ${mesesComunesDetalle.length}`,
    );
    console.log(
      `   Por año:`,
      aniosAConsultar
        .map((a) => {
          const count = mesesComunesDetalle.filter((m) => m.anio === a).length;
          return `${a}: ${count} meses`;
        })
        .join(", "),
    );

    handleSuccess(res, 200, "Meses no pagados obtenidos exitosamente", {
      estudiantes: estudiantesConMeses,
      mesesComunes: mesesComunesDetalle,
      totalEstudiantes: dependientes.length,
      anios: aniosAConsultar,
      totalMesesDisponibles: mesesComunesDetalle.length,
      // Para facilitar UI: listado de meses exentos por estudiante
      mesesExentosGlobal: Array.from(
        new Set(estudiantesConMeses.flatMap((e) => e.mesesExentos)),
      ),
    });
  } catch (error) {
    console.error("Error obteniendo meses no pagados:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
