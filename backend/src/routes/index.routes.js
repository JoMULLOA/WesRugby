"use strict";
import { Router } from "express";
import userRoutes from "./user.routes.js";
import authRoutes from "./auth.routes.js";
import notificacionRoutes from "./notificacion.routes.js";

// Rutas para modulos de rugby
import planPagoRoutes from "./planPago.routes.js";
import asistenciaRoutes from "./asistencia.routes.js";
import comprobantePagoRoutes from "./comprobantePago.routes.js";
import eventoDeportivoRoutes from "./eventoDeportivo.routes.js";
import directivaRoutes from "./directiva.routes.js";
import estudianteRoutes from "./estudiante.routes.js";
import importacionRoutes from "./importacion.routes.js";
import sesionAsistenciaRoutes from "./sesionAsistencia.routes.js";
import torneoRoutes from "./torneo.routes.js";
import eventoRoutes from "./evento.routes.js";
import tipoEventoRoutes from "./tipoEvento.routes.js";
import actaReunionRoutes from "./actaReunion.routes.js";

// Rutas para informacion publica
import noticiaRoutes from "./noticia.routes.js";
import auspiciadorRoutes from "./auspiciador.routes.js";
import merchandisingRoutes from "./merchandising.routes.js";
import homepageRoutes from "./homepage.routes.js";
import uploadRoutes from "./upload.routes.js";
import inventoryRoutes from "./inventory.routes.js";
import configuracionPrecioRoutes from "./configuracionPrecio.routes.js";
import clubRoutes from "./club.routes.js";

const router = Router();

router
    .use("/auth", authRoutes)
    .use("/user", userRoutes)
    .use("/notificaciones", notificacionRoutes)
    // Rutas modulos rugby
    .use("/planes-pago", planPagoRoutes)
    .use("/asistencia", asistenciaRoutes)
    .use("/comprobantes-pago", comprobantePagoRoutes)
    .use("/eventos-deportivos", eventoDeportivoRoutes)
    .use("/directiva", directivaRoutes)
    .use("/estudiantes", estudianteRoutes)
    .use("/importacion", importacionRoutes)
    .use("/sesiones-asistencia", sesionAsistenciaRoutes)
    .use("/torneos", torneoRoutes)
    .use("/eventos", eventoRoutes)
    .use("/tipos-evento", tipoEventoRoutes)
    .use("/actas-reunion", actaReunionRoutes)
    // Rutas informacion publica
    .use("/noticias", noticiaRoutes)
    .use("/auspiciadores", auspiciadorRoutes)
    .use("/merchandising", merchandisingRoutes)
    .use("/homepage", homepageRoutes)
    .use("/inventario", inventoryRoutes)
    .use("/configuracion-precios", configuracionPrecioRoutes)
    .use("/club", clubRoutes)
    .use("/upload", uploadRoutes);

export default router;
