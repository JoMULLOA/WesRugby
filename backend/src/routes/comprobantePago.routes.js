import { Router } from "express";
import {
  crearComprobantePago,
  obtenerComprobantesPago,
  obtenerComprobantePorId,
  validarComprobante,
  actualizarComprobante,
  obtenerEstadisticasPagos,
  eliminarComprobante,
  obtenerInscripcionesApoderado,
  subirVoucherMensualidadApoderado,
  subirVoucherMatriculaApoderado,
  obtenerHistorialApoderado,
  reenviarComprobanteApoderado,
  obtenerMesesNoPagados2025,
} from "../controllers/comprobantePago.controller.js";

import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import {
  isDirectiva,
  isTesorera,
  isAuthenticated,
  isApoderado,
} from "../middlewares/authorization.middleware.js";
import { uploadVoucherComprobante } from "../middlewares/upload.middleware.js";

const router = Router();

// Crear comprobante de pago (Tesorería o Directiva)
router.post("/", authenticateJwt, isTesorera, crearComprobantePago);

// Obtener comprobantes (Todos los autenticados)
router.get("/", authenticateJwt, isAuthenticated, obtenerComprobantesPago);

// Obtener estadísticas (Tesorería o Directiva)
router.get("/estadisticas/resumen", authenticateJwt, isTesorera, obtenerEstadisticasPagos);

// Endpoints para apoderados
router.get(
  "/apoderado/inscripciones",
  authenticateJwt,
  isApoderado,
  obtenerInscripcionesApoderado,
);

router.get(
  "/apoderado/meses-no-pagados-2025",
  authenticateJwt,
  isApoderado,
  obtenerMesesNoPagados2025,
);

router.get(
  "/apoderado/historial",
  authenticateJwt,
  isApoderado,
  obtenerHistorialApoderado,
);

router.get(
  "/apoderado/mis-vouchers",
  authenticateJwt,
  isApoderado,
  obtenerHistorialApoderado,
);

router.post(
  "/apoderado/voucher-mensualidad",
  authenticateJwt,
  isApoderado,
  uploadVoucherComprobante.single("voucher"),
  subirVoucherMensualidadApoderado,
);

router.post(
  "/apoderado/voucher-matricula",
  authenticateJwt,
  isApoderado,
  uploadVoucherComprobante.single("voucher"),
  subirVoucherMatriculaApoderado,
);

router.post(
  "/apoderado/:id/reenviar-comprobante",
  authenticateJwt,
  isApoderado,
  reenviarComprobanteApoderado,
);

// Obtener comprobante por ID (Todos los autenticados)
router.get("/:id", authenticateJwt, isAuthenticated, obtenerComprobantePorId);

// Validar comprobante (Tesorera, Directiva)
router.patch("/:id/validar", authenticateJwt, isTesorera, validarComprobante);

// Actualizar comprobante (Todos los autenticados con restricciones)
router.put("/:id", authenticateJwt, isAuthenticated, actualizarComprobante);

// Eliminar comprobante (Solo Directiva)
router.delete("/:id", authenticateJwt, isDirectiva, eliminarComprobante);

export default router;
