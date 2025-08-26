"use strict";
import { Router } from "express";
import userRoutes from "./user.routes.js";
import authRoutes from "./auth.routes.js";
import amistadRoutes from "./amistad.routes.js";
import notificacionRoutes from "./notificacion.routes.js";
import contactoEmergenciaRoutes from "./contactoEmergencia.routes.js";
import peticionSupervisionRoutes from "./peticionSupervision.routes.js";
import transaccionRoutes from "./transaccion.routes.js";

// Nuevas rutas para módulos de rugby
import inscripcionRoutes from "./inscripcion.routes.js";
import planPagoRoutes from "./planPago.routes.js";
import asistenciaRoutes from "./asistencia.routes.js";
import comprobantePagoRoutes from "./comprobantePago.routes.js";
import eventoDeportivoRoutes from "./eventoDeportivo.routes.js";
import productoRoutes from "./producto.routes.js";
import ventaProductoRoutes from "./ventaProducto.routes.js";
import directivaRoutes from "./directiva.routes.js";

const router = Router();

router
    .use("/auth", authRoutes)
    .use("/user", userRoutes)
    .use("/amistad", amistadRoutes)
    .use("/notificaciones", notificacionRoutes)
    .use("/contactos-emergencia", contactoEmergenciaRoutes)
    .use("/peticiones-supervision", peticionSupervisionRoutes)
    .use("/transacciones", transaccionRoutes)
    // Rutas módulos rugby
    .use("/inscripciones", inscripcionRoutes)
    .use("/planes-pago", planPagoRoutes)
    .use("/asistencia", asistenciaRoutes)
    .use("/comprobantes-pago", comprobantePagoRoutes)
    .use("/eventos-deportivos", eventoDeportivoRoutes)
    .use("/productos", productoRoutes)
    .use("/ventas", ventaProductoRoutes)
    .use("/directiva", directivaRoutes);

export default router;