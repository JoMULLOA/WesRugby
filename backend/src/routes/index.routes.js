"use strict";
import { Router } from "express";
import userRoutes from "./user.routes.js";
import authRoutes from "./auth.routes.js";
import amistadRoutes from "./amistad.routes.js";
import notificacionRoutes from "./notificacion.routes.js";
import contactoEmergenciaRoutes from "./contactoEmergencia.routes.js";
import peticionSupervisionRoutes from "./peticionSupervision.routes.js";
import transaccionRoutes from "./transaccion.routes.js";

const router = Router();

router
    .use("/auth", authRoutes)
    .use("/user", userRoutes)
    .use("/amistad", amistadRoutes)
    .use("/notificaciones", notificacionRoutes)
    .use("/contactos-emergencia", contactoEmergenciaRoutes)
    .use("/peticiones-supervision", peticionSupervisionRoutes)
    .use("/transacciones", transaccionRoutes)
export default router;