"use strict";
/**
 * testApp.js — Fábrica de la aplicación Express para tests de integración.
 *
 * En lugar de importar src/index.js (que llama a app.listen y arranca cron
 * jobs, etc.), construimos la misma pila de middlewares + rutas pero
 * devolvemos la instancia de Express sin escuchar en ningún puerto:
 * Supertest abre el socket internamente durante la prueba.
 *
 * Flujo:
 *   buildTestApp() →
 *     1. connectDB()         : inicializar TypeORM (dropSchema + synchronize)
 *     2. passportJwtSetup()  : registrar la estrategia JWT en Passport
 *     3. createInitialData() : sembrar usuarios y datos base
 *     4. armar Express app   : mismo middleware stack que index.js
 *     5. return app          : Supertest lo usa vía request(app)
 *
 * IMPORTANTE: las variables de entorno siguen leyéndose desde process.env
 * tal como hace configEnv.js, por lo que el CI puede inyectarlas como
 * secretos del Service Container de GitHub Actions.
 */

import express, { json, urlencoded } from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import session from "express-session";
import passport from "passport";

import { AppDataSource, connectDB } from "../../../src/config/configDb.js";
import { passportJwtSetup } from "../../../src/auth/passport.auth.js";
import { createInitialData } from "../../../src/config/initialSetup.js";
import { cookieKey } from "../../../src/config/configEnv.js";
import indexRoutes from "../../../src/routes/index.routes.js";

/**
 * Crea y devuelve una instancia de Express lista para usar con Supertest.
 * Llama a connectDB() que — gracias a dropSchema:true en configDb.js —
 * recrea el esquema desde cero, garantizando aislamiento entre ejecuciones.
 *
 * @returns {Promise<import("express").Express>}
 */
export async function buildTestApp() {
  // Si ya está inicializado (reutilización del módulo entre archivos con
  // fileParallelism:false), destruir primero para obtener un schema limpio.
  // dropSchema:true en configDb.js recrea las tablas en cada initialize().
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
  }

  await connectDB();

  // Registrar estrategia JWT en Passport (idempotente)
  passportJwtSetup();

  // Sembrar usuarios y datos predeterminados
  await createInitialData();

  // --- Construir la app Express ---
  const app = express();

  app.disable("x-powered-by");
  app.set("trust proxy", true);

  app.use(cors({ credentials: true, origin: true }));
  app.use(urlencoded({ extended: true, limit: "5mb" }));
  app.use(json({ limit: "10mb" }));
  app.use(cookieParser());

  app.use(
    session({
      secret: cookieKey,
      resave: false,
      saveUninitialized: false,
      cookie: { secure: false, httpOnly: true, sameSite: "strict" },
    }),
  );

  app.use(passport.initialize());
  app.use(passport.session());

  // Todas las rutas de la API (mismo índice que en producción)
  app.use("/api", indexRoutes);

  return app;
}

// Re-exportar AppDataSource para que los tests puedan cerrar la conexión
// en afterAll con AppDataSource.destroy()
export { AppDataSource };
