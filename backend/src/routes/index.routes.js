"use strict";
import { Router } from "express";
import userRoutes from "./user.routes.js";
import authRoutes from "./auth.routes.js";
import notificacionRoutes from "./notificacion.routes.js";

// Rutas para módulos de rugby
import planPagoRoutes from "./planPago.routes.js";
import asistenciaRoutes from "./asistencia.routes.js";
import comprobantePagoRoutes from "./comprobantePago.routes.js";
import eventoDeportivoRoutes from "./eventoDeportivo.routes.js";
import directivaRoutes from "./directiva.routes.js";
import estudianteRoutes from "./estudiante.routes.js";
import importacionRoutes from "./importacion.routes.js";
import torneoRoutes from "./torneo.routes.js";
import eventoRoutes from "./evento.routes.js";
import tipoEventoRoutes from "./tipoEvento.routes.js";

const router = Router();

router
    .use("/auth", authRoutes)
    .use("/user", userRoutes)
    .use("/notificaciones", notificacionRoutes)
    // Rutas módulos rugby
    .use("/planes-pago", planPagoRoutes)
    .use("/asistencia", asistenciaRoutes)
    .use("/comprobantes-pago", comprobantePagoRoutes)
    .use("/eventos-deportivos", eventoDeportivoRoutes)
    .use("/directiva", directivaRoutes)
    .use("/estudiantes", estudianteRoutes)
    .use("/importacion", importacionRoutes)
    .use("/torneos", torneoRoutes)
    .use("/eventos", eventoRoutes)
    .use("/tipos-evento", tipoEventoRoutes);

export default router;