"use strict";
import { AppDataSource } from "../config/configDb.js";
import Estudiante from "../entity/estudiante.entity.js";
import User from "../entity/user.entity.js";
import {
  createEstudianteService,
  updateEstudianteService,
} from "../services/estudiante.service.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";
import { createHash } from "crypto";

const MESES = [
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

const COLUMN_ALIASES = {
  nombre: ["nombre", "nombrecompleto"],
  fechaNacimiento: ["fechanacimiento", "fechadenacimiento"],
  rut: ["rut", "run"],
  categoria: ["categoria"],
  ficha: ["ficha"],
  curso: ["curso"],
  nombreMadre: ["nombremadre"],
  telefonoMadre: ["ntelefonomadre", "ntelefonmadre", "telefonomadre", "numerotelefonomadre"],
  emailMadre: ["correoelectronicomadre", "emailmadre"],
  nombrePadre: ["nombrepadre"],
  telefonoPadre: ["ntelefonopadre", "telefonompadre", "telefonopadre", "numerotelefonopadre"],
  emailPadre: ["correoelectronicopadre", "emailpadre"],
  hermanos: ["hermanos"],
  enfermedad: ["enfermedad"],
  talla: ["talla"],
  dorsalNombre: ["dorsalnombre", "dorsal"],
  alumnoNuevo: ["alumnonuevo"],
  asistencia: ["asistencia"],
  matricula: ["matricula"],
  marzo: ["marzo"],
  abril: ["abril"],
  mayo: ["mayo"],
  junio: ["junio"],
  julio: ["julio"],
  agosto: ["agosto"],
  septiembre: ["septiembre"],
  octubre: ["octubre"],
  noviembre: ["noviembre"],
  diciembre: ["diciembre"],
  totalAnio: ["totalano", "totalanio", "totalanno"],
  poleron: ["poleron"],
  calcetas: ["calcetas"],
  protectorBucal: ["protectorbucal"],
  uniforme: ["uniforme"],
  anadido: ["anadido", "anadidoadicional"],
  responsable: ["responsable", "apoderado", "apoderadoresponsable"],
};

const DEFAULT_GUARDIAN_PASSWORD = "wessex123";
const GUARDIAN_EMAIL_DOMAIN = "@wessex.cl";
const MAX_EMAIL_LOCAL_LENGTH = 30;
const GUARDIAN_RUT_PREFIX = "AP";

function normalizeKey(key) {
  return key
    .toString()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]/g, "");
}

function pickValue(rowMap, aliases) {
  for (const alias of aliases) {
    const normalizedAlias = normalizeKey(alias);
    if (normalizedAlias in rowMap) {
      return rowMap[normalizedAlias];
    }
  }
  return null;
}

function toTitleCase(value) {
  return value
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function cleanString(value) {
  if (value === null || value === undefined) return "";
  return value.toString().trim();
}

function removeDiacritics(value) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-zA-Z0-9\s]/g, "");
}

function normalizeRut(raw) {
  const value = cleanString(raw);
  if (!value) {
    throw new Error("RUT es obligatorio");
  }
  const cleaned = value.replace(/[^0-9kK]/g, "").toUpperCase();
  if (cleaned.length < 2) {
    throw new Error("RUT invalido");
  }
  const cuerpo = cleaned.slice(0, -1).padStart(8, "0");
  const dv = cleaned.slice(-1);
  return `${cuerpo}-${dv}`;
}

function parseFecha(raw) {
  const value = cleanString(raw);
  if (!value) {
    throw new Error("Fecha de nacimiento es obligatoria");
  }
  const match = value.match(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})/);
  if (!match) {
    throw new Error("Formato de fecha invalido (dd-mm-yy)");
  }
  const day = parseInt(match[1], 10);
  const month = parseInt(match[2], 10);
  let year = parseInt(match[3], 10);
  if (year < 100) {
    const currentYear = new Date().getFullYear() % 100;
    year += year > currentYear ? 1900 : 2000;
  }
  const date = new Date(Date.UTC(year, month - 1, day));
  if (Number.isNaN(date.getTime())) {
    throw new Error("Fecha de nacimiento invalida");
  }
  return date;
}

function normalizeCategoria(raw) {
  const value = cleanString(raw).toUpperCase();
  if (!value) {
    throw new Error("Categoria es obligatoria");
  }
  if (!/^M\d{1,2}$/.test(value)) {
    throw new Error("Categoria invalida, formato esperado M + numero");
  }
  return value;
}

function normalizeFicha(raw) {
  const value = cleanString(raw).toLowerCase();
  if (!value) return null;
  if (["si", "sí", "s", "1", "true"].includes(value)) return true;
  if (["no", "n", "0", "false"].includes(value)) return false;
  return null;
}

function normalizeCurso(raw) {
  const value = cleanString(raw).toUpperCase();
  if (!value) {
    throw new Error("Curso es obligatorio");
  }
  return value.slice(0, 2);
}

function normalizePhone(raw) {
  const value = cleanString(raw);
  if (!value) return null;
  let digits = value.replace(/\D/g, "");
  if (digits.length === 11) {
    digits = digits.slice(2);
  }
  if (digits.length === 8) {
    digits = `9${digits}`;
  }
  if (digits.length !== 9) {
    throw new Error("Debe tener 9 digitos despues de limpiar");
  }
  return digits;
}

function normalizeEmail(raw) {
  const value = cleanString(raw).toLowerCase();
  if (!value) return null;
  if (value.includes(" ") || !value.includes("@")) {
    throw new Error("Correo invalido");
  }
  return value;
}

function normalizeTalla(raw) {
  const value = cleanString(raw);
  if (!value) return null;
  return value.toUpperCase();
}

function normalizeTexto(raw) {
  const value = cleanString(raw);
  return value || null;
}

function parseHermanos(raw) {
  const value = cleanString(raw);
  if (!value) return [];
  const candidatos = value
    .split(/[;,\/\n]/)
    .map((item) => item.trim())
    .filter(Boolean);
  const resultado = [];
  for (const candidato of candidatos) {
    try {
      resultado.push(normalizeRut(candidato));
    } catch (error) {
      // omit invalid sibling rut but continue
    }
  }
  return Array.from(new Set(resultado));
}

function normalizePago(raw) {
  const value = cleanString(raw);
  return value ? value : "no pagado";
}

function buildPagos(rowMap) {
  const pagos = {
    anio: 2025, // Identificar que estos pagos son del año 2025
    matricula: normalizePago(pickValue(rowMap, COLUMN_ALIASES.matricula) ?? ""),
    meses: {},
    totalAnio: normalizePago(pickValue(rowMap, COLUMN_ALIASES.totalAnio) ?? ""),
  };
  for (const mes of MESES) {
    const raw = pickValue(rowMap, COLUMN_ALIASES[mes]) ?? "";
    pagos.meses[mes] = normalizePago(raw);
  }
  return pagos;
}

function buildEquipamiento(rowMap) {
  return {
    poleron: cleanString(pickValue(rowMap, COLUMN_ALIASES.poleron) ?? ""),
    calcetas: cleanString(pickValue(rowMap, COLUMN_ALIASES.calcetas) ?? ""),
    protectorBucal: cleanString(pickValue(rowMap, COLUMN_ALIASES.protectorBucal) ?? ""),
    uniforme: cleanString(pickValue(rowMap, COLUMN_ALIASES.uniforme) ?? ""),
    anadido: cleanString(pickValue(rowMap, COLUMN_ALIASES.anadido) ?? ""),
  };
}

function resolveResponsable(
  raw,
  {
    nombreMadre,
    telefonoMadre,
    emailMadre,
    nombrePadre,
    telefonoPadre,
    emailPadre,
  },
) {
  const info = {
    etiqueta: null,
    nombre: null,
    telefono: null,
    email: null,
    warning: null,
  };

  const madreInfo = nombreMadre
    ? {
        etiqueta: "Madre",
        nombre: nombreMadre,
        telefono: telefonoMadre,
        email: emailMadre,
      }
    : null;
  const padreInfo = nombrePadre
    ? {
        etiqueta: "Padre",
        nombre: nombrePadre,
        telefono: telefonoPadre,
        email: emailPadre,
      }
    : null;

  const cleaned = cleanString(raw);
  if (!cleaned) {
    return madreInfo ?? padreInfo ?? { ...info, etiqueta: "Madre" };
  }

  const normalized = removeDiacritics(cleaned).toLowerCase();

  if (["madre", "mama", "mamá"].includes(normalized)) {
    if (madreInfo) {
      return madreInfo;
    }
    return {
      ...info,
      etiqueta: "Madre",
      nombre: "Madre",
      warning: "Responsable definido como Madre pero no se encontró nombre de la madre en el registro",
    };
  }

  if (["padre", "papa", "papá"].includes(normalized)) {
    if (padreInfo) {
      return padreInfo;
    }
    return {
      ...info,
      etiqueta: "Padre",
      nombre: "Padre",
      warning: "Responsable definido como Padre pero no se encontró nombre del padre en el registro",
    };
  }

  const nombrePersonalizado = toTitleCase(cleaned);
  return {
    etiqueta: nombrePersonalizado,
    nombre: nombrePersonalizado,
    telefono: madreInfo?.telefono ?? padreInfo?.telefono ?? null,
    email: madreInfo?.email ?? padreInfo?.email ?? null,
  };
}

function buildGuardianEmailBase(nombreReferencia) {
  const cleaned = cleanString(nombreReferencia);
  if (!cleaned) {
    return null;
  }
  const tokens = removeDiacritics(cleaned.toLowerCase())
    .split(/\s+/)
    .map((token) => token.replace(/[^a-z0-9]/g, ""))
    .filter(Boolean);
  if (tokens.length === 0) {
    return null;
  }
  const first = tokens[0];
  let last = tokens.length > 1 ? tokens[tokens.length - 1] : "";
  if (!last || last === first) {
    const alternative = tokens.find((token) => token !== first);
    if (alternative) {
      last = alternative;
    }
  }
  const parts = [first];
  if (last && last !== first) {
    parts.push(last);
  }
  return parts.join(".");
}

function generateGuardianEmail({
  guardianName,
  fallbackName,
  rut,
  guardianEmailsInUse,
  guardianEmailsBatch,
  existingEmail,
}) {
  if (existingEmail) {
    const normalizedExisting = existingEmail.toLowerCase();
    guardianEmailsBatch.add(normalizedExisting);
    guardianEmailsInUse.add(normalizedExisting);
    return normalizedExisting;
  }

  const baseCandidates = [
    buildGuardianEmailBase(guardianName),
    buildGuardianEmailBase(fallbackName),
  ];

  let base = baseCandidates.find((candidate) => candidate) ?? null;

  if (!base) {
    const digits = cleanString(rut).replace(/[^0-9]/g, "");
    if (digits) {
      base = `${GUARDIAN_RUT_PREFIX.toLowerCase()}${digits.slice(-6)}`;
    }
  }

  if (!base) {
    return null;
  }

  base = base
    .replace(/\.+/g, ".")
    .replace(/^\./, "")
    .replace(/\.$/, "")
    .slice(0, Math.max(1, MAX_EMAIL_LOCAL_LENGTH - 3));

  if (!base) {
    return null;
  }

  let attempt = 0;
  while (attempt < 1000) {
    const numericSuffix = attempt === 0 ? "0" : `${attempt}`;
    let localPart = `${base}${numericSuffix}`;
    if (localPart.length > MAX_EMAIL_LOCAL_LENGTH) {
      localPart = localPart.slice(0, MAX_EMAIL_LOCAL_LENGTH);
    }
    const candidate = `${localPart}${GUARDIAN_EMAIL_DOMAIN}`.toLowerCase();
    if (!guardianEmailsInUse.has(candidate) && !guardianEmailsBatch.has(candidate)) {
      guardianEmailsBatch.add(candidate);
      guardianEmailsInUse.add(candidate);
      return candidate;
    }
    attempt += 1;
  }

  return null;
}

function determineGuardianNameForEmail(data) {
  const candidates = [
    data.nombreResponsable,
    data.responsableEtiqueta && data.responsableEtiqueta.toLowerCase() === "madre"
      ? data.nombreMadre
      : null,
    data.responsableEtiqueta && data.responsableEtiqueta.toLowerCase() === "padre"
      ? data.nombrePadre
      : null,
    data.nombreMadre,
    data.nombrePadre,
  ];

  for (const candidato of candidates) {
    const cleaned = cleanString(candidato);
    if (cleaned) {
      return cleaned;
    }
  }

  return cleanString(data.nombreResponsable) || cleanString(data.nombre) || null;
}

function generateGuardianRut(email, guardianRutsInUse) {
  const normalizedEmail = cleanString(email).toLowerCase();
  const hash = createHash("sha1").update(normalizedEmail).digest("hex").toUpperCase();
  let base = `${GUARDIAN_RUT_PREFIX}${hash.slice(0, 9)}`;
  if (base.length > 12) {
    base = base.slice(0, 12);
  }

  if (!guardianRutsInUse.has(base)) {
    return base;
  }

  for (let attempt = 1; attempt < 100; attempt += 1) {
    const suffix = attempt.toString().padStart(2, "0");
    const candidate = `${base.slice(0, 12 - suffix.length)}${suffix}`;
    if (!guardianRutsInUse.has(candidate)) {
      return candidate;
    }
  }

  let fallback = `${GUARDIAN_RUT_PREFIX}${Date.now().toString().slice(-10)}`.slice(0, 12);
  while (guardianRutsInUse.has(fallback)) {
    fallback = `${GUARDIAN_RUT_PREFIX}${Math.floor(Math.random() * 1e9)
      .toString()
      .padStart(9, "0")}`.slice(0, 12);
  }
  return fallback;
}

async function ensureGuardianUser({
  userRepository,
  guardianUsersCache,
  guardianRutsInUse,
  email,
  nombre,
}) {
  const normalizedEmail = cleanString(email).toLowerCase();
  if (!normalizedEmail) {
    return { user: null, created: false };
  }

  if (guardianUsersCache.has(normalizedEmail)) {
    return { user: guardianUsersCache.get(normalizedEmail), created: false };
  }

  const existingUser = await userRepository.findOne({ where: { email: normalizedEmail } });
  if (existingUser) {
    guardianUsersCache.set(normalizedEmail, existingUser);
    if (existingUser.rut) {
      guardianRutsInUse.add(existingUser.rut);
    }
    return { user: existingUser, created: false };
  }

  const displayName = toTitleCase(cleanString(nombre)) || toTitleCase(normalizedEmail.split("@")[0]);
  const rut = generateGuardianRut(normalizedEmail, guardianRutsInUse);
  guardianRutsInUse.add(rut);
  const passwordHash = await encryptPassword(DEFAULT_GUARDIAN_PASSWORD);
  const newUser = userRepository.create({
    rut,
    nombreCompleto: displayName,
    email: normalizedEmail,
    password: passwordHash,
    rol: "apoderado",
  });
  const savedUser = await userRepository.save(newUser);
  guardianUsersCache.set(normalizedEmail, savedUser);
  return { user: savedUser, created: true };
}

function buildObservaciones(data) {
  const partes = [];
  if (data.enfermedad) {
    partes.push(`Enfermedad: ${data.enfermedad}`);
  }
  if (data.alumnoNuevo) {
    partes.push(`Alumno nuevo: ${data.alumnoNuevo}`);
  }
  if (data.asistencia) {
    partes.push(`Asistencia: ${data.asistencia}`);
  }
  return partes.length > 0 ? partes.join(" | ") : null;
}

function normalizeRow(row) {
  const rowMap = Object.entries(row).reduce((acc, [key, value]) => {
    acc[normalizeKey(key)] = value;
    return acc;
  }, {});

  const warnings = [];

  const nombreRaw = pickValue(rowMap, COLUMN_ALIASES.nombre);
  const nombre = toTitleCase(cleanString(nombreRaw));
  if (!nombre) {
    throw new Error("Nombre es obligatorio");
  }

  const rut = normalizeRut(pickValue(rowMap, COLUMN_ALIASES.rut));
  const fechaNacimiento = parseFecha(pickValue(rowMap, COLUMN_ALIASES.fechaNacimiento));
  const categoria = normalizeCategoria(pickValue(rowMap, COLUMN_ALIASES.categoria));
  const ficha = normalizeFicha(pickValue(rowMap, COLUMN_ALIASES.ficha));
  const curso = normalizeCurso(pickValue(rowMap, COLUMN_ALIASES.curso));

  const nombreMadreRaw = normalizeTexto(pickValue(rowMap, COLUMN_ALIASES.nombreMadre));
  const nombreMadre = nombreMadreRaw ? toTitleCase(nombreMadreRaw) : null;
  let telefonoMadre = null;
  try {
    telefonoMadre = normalizePhone(pickValue(rowMap, COLUMN_ALIASES.telefonoMadre));
  } catch (error) {
    if (nombreMadre) {
      warnings.push(`Telefono madre invalido: ${error.message}`);
    }
  }
  let emailMadre = null;
  try {
    emailMadre = normalizeEmail(pickValue(rowMap, COLUMN_ALIASES.emailMadre));
  } catch (error) {
    warnings.push(`Correo madre invalido: ${error.message}`);
  }

  const nombrePadreRaw = normalizeTexto(pickValue(rowMap, COLUMN_ALIASES.nombrePadre));
  const nombrePadre = nombrePadreRaw ? toTitleCase(nombrePadreRaw) : null;
  let telefonoPadre = null;
  try {
    telefonoPadre = normalizePhone(pickValue(rowMap, COLUMN_ALIASES.telefonoPadre));
  } catch (error) {
    if (nombrePadre) {
      warnings.push(`Telefono padre invalido: ${error.message}`);
    }
  }
  let emailPadre = null;
  try {
    emailPadre = normalizeEmail(pickValue(rowMap, COLUMN_ALIASES.emailPadre));
  } catch (error) {
    warnings.push(`Correo padre invalido: ${error.message}`);
  }

  const hermanos = parseHermanos(pickValue(rowMap, COLUMN_ALIASES.hermanos));
  const enfermedad = normalizeTexto(pickValue(rowMap, COLUMN_ALIASES.enfermedad));
  const talla = normalizeTalla(pickValue(rowMap, COLUMN_ALIASES.talla));
  const dorsalNombre = normalizeTexto(pickValue(rowMap, COLUMN_ALIASES.dorsalNombre));
  const alumnoNuevo = normalizeTexto(pickValue(rowMap, COLUMN_ALIASES.alumnoNuevo));
  const asistencia = normalizeTexto(pickValue(rowMap, COLUMN_ALIASES.asistencia));
  const pagos = buildPagos(rowMap);
  const equipamiento = buildEquipamiento(rowMap);
  const responsableInfo = resolveResponsable(pickValue(rowMap, COLUMN_ALIASES.responsable), {
    nombreMadre,
    telefonoMadre,
    emailMadre,
    nombrePadre,
    telefonoPadre,
    emailPadre,
  });

  if (responsableInfo.warning) {
    warnings.push(responsableInfo.warning);
  }

  const nombreResponsableNormalizado = responsableInfo.nombre
    ? toTitleCase(responsableInfo.nombre)
    : null;

  return {
    data: {
      rut,
      nombre,
      fechaNacimiento,
      categoria,
      ficha,
      curso,
      nombreMadre,
      telefonoMadre,
      emailMadre,
      nombrePadre,
      telefonoPadre,
      emailPadre,
      hermanos,
      enfermedad,
      talla,
      dorsalNombre,
      alumnoNuevo,
      asistencia,
      pagos,
      equipamiento,
      responsableEtiqueta: responsableInfo.etiqueta,
      nombreResponsable: nombreResponsableNormalizado,
      telefonoResponsable: responsableInfo.telefono,
      emailResponsable: responsableInfo.email,
      rutResponsable: null,
    },
    warnings,
  };
}

function buildEstudiantePayload(normalized) {
  const nombreResponsable =
    normalized.nombreResponsable || normalized.responsableEtiqueta || null;
  const contactoEmergencia =
    nombreResponsable || normalized.nombreMadre || normalized.nombrePadre || null;
  const telefonoPrincipal =
    normalized.telefonoResponsable ||
    normalized.telefonoMadre ||
    normalized.telefonoPadre ||
    null;
  const telefonoEmergencia =
    telefonoPrincipal ||
    normalized.telefonoMadre ||
    normalized.telefonoPadre ||
    null;
  return {
    rut: normalized.rut,
    nombre: normalized.nombre,
    categoria: normalized.categoria,
    ficha: normalized.ficha,
    curso: normalized.curso,
    fechaNacimiento: normalized.fechaNacimiento,
    correoApoderadoGenerado: normalized.correoApoderadoGenerado,
    telefono: telefonoPrincipal,
    direccion: null,
    email: null,
    contactoEmergencia,
    telefonoEmergencia,
    rutResponsable: normalized.rutResponsable ?? null,
    nombreResponsable,
    rutResponsable2: null,
    nombreResponsable2: null,
    observaciones: buildObservaciones(normalized),
    estado: "activo",
    nombreMadre: normalized.nombreMadre,
    telefonoMadre: normalized.telefonoMadre,
    emailMadre: normalized.emailMadre,
    nombrePadre: normalized.nombrePadre,
    telefonoPadre: normalized.telefonoPadre,
    emailPadre: normalized.emailPadre,
    hermanos: normalized.hermanos,
    enfermedad: normalized.enfermedad,
    talla: normalized.talla,
    dorsalNombre: normalized.dorsalNombre,
    alumnoNuevo: normalized.alumnoNuevo,
    asistencia: normalized.asistencia,
    pagos: normalized.pagos,
    equipamiento: normalized.equipamiento,
  };
}

function mergeForUpdate(payload) {
  const updatePayload = { ...payload };
  delete updatePayload.rut;
  return updatePayload;
}

async function syncSiblingRelationships(siblingMap, estudianteRepository, results) {
  for (const [rut, hermanosSet] of siblingMap.entries()) {
    try {
      const estudiante = await estudianteRepository.findOne({ where: { rut } });
      if (!estudiante) continue;
      const actuales = new Set(Array.isArray(estudiante.hermanos) ? estudiante.hermanos : []);
      let actualizado = false;
      hermanosSet.forEach((hermanoRut) => {
        if (!actuales.has(hermanoRut)) {
          actuales.add(hermanoRut);
          actualizado = true;
        }
      });
      if (actualizado) {
        estudiante.hermanos = Array.from(actuales);
        await estudianteRepository.save(estudiante);
      }
      for (const hermanoRut of hermanosSet) {
        const hermano = await estudianteRepository.findOne({ where: { rut: hermanoRut } });
        if (!hermano) continue;
        const hermanoSet = new Set(Array.isArray(hermano.hermanos) ? hermano.hermanos : []);
        if (!hermanoSet.has(rut)) {
          hermanoSet.add(rut);
          hermano.hermanos = Array.from(hermanoSet);
          await estudianteRepository.save(hermano);
        }
      }
    } catch (error) {
      results.errores.push({ estudiante: rut, error: `Error asociando hermanos: ${error.message}` });
    }
  }
}

export async function importEstudiantesFromExcel(req, res) {
  try {
    const { estudiantes } = req.body;

    if (!estudiantes || !Array.isArray(estudiantes) || estudiantes.length === 0) {
      return handleErrorClient(res, 400, "Lista de estudiantes es requerida");
    }

    const estudianteRepository = AppDataSource.getRepository(Estudiante);
    const userRepository = AppDataSource.getRepository(User);

    const existentes = await estudianteRepository.find();
    const estudiantesMap = new Map(existentes.map((item) => [item.rut, item]));
    const guardianEmailsInUse = new Set(
      existentes
        .map((item) => item.correoApoderadoGenerado?.toLowerCase())
        .filter(Boolean),
    );
    const guardianEmailsBatch = new Set();
    const guardianUsersCache = new Map();
    const guardianRutsInUse = new Set();
  const guardianAssignmentsByRut = new Map();
  const guardianSiblingUpdates = new Map();
  const processedStudentRuts = new Set();
  const guardianSiblingUpdateDetails = [];

    const existingUsers = await userRepository.find();
    existingUsers.forEach((user) => {
      if (user.email) {
        const normalizedEmail = user.email.toLowerCase();
        guardianUsersCache.set(normalizedEmail, user);
        guardianEmailsInUse.add(normalizedEmail);
      }
      if (user.rut) {
        guardianRutsInUse.add(user.rut);
      }
    });

    const siblingMap = new Map();

    const results = {
      estudiantesCreados: [],
      estudiantesActualizados: [],
      errores: [],
      advertencias: [],
    };
    const guardianCreationDetails = [];
    let guardianEmailsGeneratedCount = 0;
    let guardianAccountsCreatedCount = 0;
  let guardianSiblingLinksUpdatedCount = 0;

    for (let i = 0; i < estudiantes.length; i += 1) {
      const row = estudiantes[i];
      try {
        const { data, warnings } = normalizeRow(row);
        const siblingRuts = Array.isArray(data.hermanos)
          ? data.hermanos.filter((rutHermano) => typeof rutHermano === "string" && rutHermano.trim())
          : [];
        const lookupRuts = [data.rut, ...siblingRuts];

        let cachedAssignment = null;
        for (const candidateRut of lookupRuts) {
          if (!candidateRut) continue;
          const assignment = guardianAssignmentsByRut.get(candidateRut);
          if (assignment) {
            cachedAssignment = assignment;
            break;
          }
        }

        if (!cachedAssignment) {
          for (const candidateRut of lookupRuts) {
            if (!candidateRut) continue;
            const estudianteRelacionado = estudiantesMap.get(candidateRut);
            if (!estudianteRelacionado) continue;
            const correoRelacionado = estudianteRelacionado.correoApoderadoGenerado
              ? estudianteRelacionado.correoApoderadoGenerado.toLowerCase()
              : null;
            if (!correoRelacionado) continue;
            cachedAssignment = {
              email: correoRelacionado,
              nombre: estudianteRelacionado.nombreResponsable || null,
              rutResponsable: estudianteRelacionado.rutResponsable || null,
              user: guardianUsersCache.get(correoRelacionado) ?? null,
            };
            break;
          }
        }

        const existingStudent = estudiantesMap.get(data.rut);
        let existingGuardianEmail = existingStudent?.correoApoderadoGenerado
          ? existingStudent.correoApoderadoGenerado.toLowerCase()
          : null;

        if (cachedAssignment?.email) {
          existingGuardianEmail = cachedAssignment.email.toLowerCase();
        }

        if (!data.rutResponsable && cachedAssignment?.rutResponsable) {
          data.rutResponsable = cachedAssignment.rutResponsable;
        }

        if (!data.nombreResponsable && cachedAssignment?.nombre) {
          data.nombreResponsable = cachedAssignment.nombre;
        }

        let guardianName = determineGuardianNameForEmail(data);
        if (!guardianName && cachedAssignment?.nombre) {
          guardianName = cachedAssignment.nombre;
        }

        const generatedEmail = generateGuardianEmail({
          guardianName,
          fallbackName: data.nombre,
          rut: data.rut,
          guardianEmailsInUse,
          guardianEmailsBatch,
          existingEmail: existingGuardianEmail,
        });
        const resolvedGuardianEmail = generatedEmail ?? existingGuardianEmail ?? null;

        if (generatedEmail && (!existingGuardianEmail || generatedEmail !== existingGuardianEmail)) {
          guardianEmailsGeneratedCount += 1;
        }

        if (resolvedGuardianEmail) {
          data.correoApoderadoGenerado = resolvedGuardianEmail;
        } else {
          warnings.push("No se pudo generar correo institucional de apoderado");
        }

        let guardianUser = cachedAssignment?.user ?? null;
        let guardianUserCreated = false;

        if (resolvedGuardianEmail) {
          const guardianDisplayName =
            toTitleCase(cleanString(guardianName)) ||
            toTitleCase(cleanString(data.nombreResponsable)) ||
            toTitleCase(cleanString(data.nombre));
          const ensured = await ensureGuardianUser({
            userRepository,
            guardianUsersCache,
            guardianRutsInUse,
            email: resolvedGuardianEmail,
            nombre: guardianDisplayName,
          });
          guardianUser = ensured.user ?? guardianUser;
          guardianUserCreated = ensured.created;
        }

        if (guardianUser && guardianUser.rut) {
          data.rutResponsable = guardianUser.rut;
          data.nombreResponsable = guardianUser.nombreCompleto || data.nombreResponsable;
          if (guardianUserCreated) {
            guardianAccountsCreatedCount += 1;
            guardianCreationDetails.push({
              estudianteRut: data.rut,
              estudiantesAsociados: Array.from(new Set([data.rut, ...siblingRuts])),
              apoderadoRut: guardianUser.rut,
              apoderadoEmail: guardianUser.email,
              apoderadoNombre: guardianUser.nombreCompleto,
            });
          }
        } else if (!data.rutResponsable && existingStudent?.rutResponsable) {
          data.rutResponsable = existingStudent.rutResponsable;
        } else if (!data.nombreResponsable && guardianName) {
          data.nombreResponsable = toTitleCase(guardianName);
        }

        if (data.correoApoderadoGenerado) {
          const normalizedEmail = data.correoApoderadoGenerado.toLowerCase();
          const assignmentForCache = {
            email: normalizedEmail,
            nombre:
              data.nombreResponsable ||
              guardianUser?.nombreCompleto ||
              (guardianName ? toTitleCase(guardianName) : null) ||
              cachedAssignment?.nombre ||
              null,
            rutResponsable:
              data.rutResponsable ||
              guardianUser?.rut ||
              cachedAssignment?.rutResponsable ||
              null,
            user: guardianUser ?? null,
          };
          const uniqueRuts = new Set(
            lookupRuts
              .filter((rutARegistrar) => typeof rutARegistrar === "string" && rutARegistrar)
              .map((rutARegistrar) => rutARegistrar.trim())
              .filter(Boolean),
          );
          uniqueRuts.forEach((rutARegistrar) => {
            guardianAssignmentsByRut.set(rutARegistrar, assignmentForCache);
          });

          if (assignmentForCache.email && assignmentForCache.rutResponsable) {
            siblingRuts.forEach((hermanoRut) => {
              if (typeof hermanoRut !== "string") return;
              const trimmedHermano = hermanoRut.trim();
              if (!trimmedHermano || trimmedHermano === data.rut) return;
              guardianSiblingUpdates.set(trimmedHermano, {
                rutResponsable: assignmentForCache.rutResponsable,
                correoApoderadoGenerado: assignmentForCache.email,
                nombreResponsable: assignmentForCache.nombre,
              });
            });
          }
        }

        if (warnings.length > 0) {
          results.advertencias.push({
            estudiante: data.rut,
            detalles: warnings,
          });
        }
        const payload = buildEstudiantePayload(data);
        const [estudiante, estudianteError] = await createEstudianteService(payload);

        if (estudianteError) {
          if (typeof estudianteError === "string" && estudianteError.includes("ya existe")) {
            const [actualizado, updateError] = await updateEstudianteService(
              data.rut,
              mergeForUpdate(payload),
            );
            if (updateError) {
              results.errores.push({ estudiante: data.rut, error: updateError });
              continue;
            }
            estudiantesMap.set(data.rut, actualizado);
            results.estudiantesActualizados.push(actualizado);
          } else {
            results.errores.push({ estudiante: data.rut, error: estudianteError });
            continue;
          }
        } else {
          estudiantesMap.set(estudiante.rut, estudiante);
          results.estudiantesCreados.push(estudiante);
        }

        processedStudentRuts.add(data.rut);

        if (data.hermanos && data.hermanos.length > 0) {
          const set = siblingMap.get(data.rut) ?? new Set();
          data.hermanos.forEach((hermanoRut) => set.add(hermanoRut));
          siblingMap.set(data.rut, set);
        }
      } catch (error) {
        results.errores.push({
          estudiante: row.nombre ?? row.Nombre ?? `Registro ${i + 1}`,
          error: error.message,
        });
      }
    }

    await syncSiblingRelationships(siblingMap, estudianteRepository, results);

    for (const [hermanoRut, updateInfo] of guardianSiblingUpdates.entries()) {
      if (processedStudentRuts.has(hermanoRut)) continue;
      try {
        const hermano = estudiantesMap.get(hermanoRut);
        if (!hermano) {
          continue;
        }

        const updatePayload = {};
        if (
          updateInfo.rutResponsable &&
          hermano.rutResponsable !== updateInfo.rutResponsable
        ) {
          updatePayload.rutResponsable = updateInfo.rutResponsable;
        }
        if (
          updateInfo.correoApoderadoGenerado &&
          (hermano.correoApoderadoGenerado || "").toLowerCase() !==
            updateInfo.correoApoderadoGenerado.toLowerCase()
        ) {
          updatePayload.correoApoderadoGenerado = updateInfo.correoApoderadoGenerado;
        }
        if (
          updateInfo.nombreResponsable &&
          hermano.nombreResponsable !== updateInfo.nombreResponsable
        ) {
          updatePayload.nombreResponsable = updateInfo.nombreResponsable;
        }

        if (Object.keys(updatePayload).length === 0) {
          continue;
        }

        const [hermanoActualizado, syncError] = await updateEstudianteService(
          hermanoRut,
          updatePayload,
        );
        if (syncError) {
          results.advertencias.push({
            estudiante: hermanoRut,
            detalles: [`No se pudo sincronizar apoderado para hermano: ${syncError}`],
          });
          continue;
        }

        estudiantesMap.set(hermanoRut, hermanoActualizado);
        processedStudentRuts.add(hermanoRut);
        results.estudiantesActualizados.push(hermanoActualizado);
        guardianSiblingLinksUpdatedCount += 1;
        guardianSiblingUpdateDetails.push({
          hermanoRut,
          apoderadoRut: updateInfo.rutResponsable,
          apoderadoEmail: updateInfo.correoApoderadoGenerado,
          apoderadoNombre: updateInfo.nombreResponsable,
        });
      } catch (errorSync) {
        results.advertencias.push({
          estudiante: hermanoRut,
          detalles: [`Error sincronizando apoderado para hermano: ${errorSync.message}`],
        });
      }
    }

    results.apoderadosCreados = guardianAccountsCreatedCount;
    results.correosApoderadoGenerados = guardianEmailsGeneratedCount;
    results.hermanosSincronizados = guardianSiblingLinksUpdatedCount;
    if (guardianCreationDetails.length > 0) {
      results.detalleApoderadosCreados = guardianCreationDetails;
    }
    if (guardianSiblingUpdateDetails.length > 0) {
      results.detalleHermanosSincronizados = guardianSiblingUpdateDetails;
    }

    const message = `Importacion completada. Nuevos: ${results.estudiantesCreados.length}, Actualizados: ${results.estudiantesActualizados.length}, Errores: ${results.errores.length}, Correos apoderado generados: ${guardianEmailsGeneratedCount}, Cuentas apoderado nuevas: ${guardianAccountsCreatedCount}, Hermanos sincronizados: ${guardianSiblingLinksUpdatedCount}`;

    handleSuccess(res, 201, message, results);
  } catch (error) {
    console.error("Error en importacion masiva:", error);
    handleErrorServer(res, 500, error.message);
  }
}