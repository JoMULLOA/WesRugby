/**
 * testApp.js — Fábrica de la aplicación Express para tests de integración.
 *
 * ARQUITECTURA:
 *  - _initialized (flag de módulo): gracias a pool:forks + singleFork:true,
 *    todos los archivos de test comparten el mismo proceso Node.js hijo, por
 *    lo que este flag persiste entre archivos. La BD se inicializa UNA SOLA VEZ.
 *  - Primera llamada a buildTestApp(): AppDataSource.initialize() con
 *    dropSchema:true (recrea el schema limpio) + seed.
 *  - Llamadas siguientes: solo TRUNCATE las tablas + reseed. Sin reconectar.
 */

import express, { json, urlencoded } from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import session from "express-session";
import passport from "passport";

import { AppDataSource } from "../../../src/config/configDb.js";
import { passportJwtSetup } from "../../../src/auth/passport.auth.js";
import { createInitialData } from "../../../src/config/initialSetup.js";
import { cookieKey } from "../../../src/config/configEnv.js";
import indexRoutes from "../../../src/routes/index.routes.js";

/** Flag de módulo: true después de la primera inicialización de TypeORM. */
let _initialized = false;

async function resetDatabase() {
  await AppDataSource.query(
    "TRUNCATE TABLE inventory_sales, inventory_scan_ingests, inventory_products, users RESTART IDENTITY CASCADE",
  );
  await createInitialData();
}

/**
 * Construye y devuelve una instancia Express lista para Supertest.
 *
 * - 1ª llamada : inicializa TypeORM (dropSchema → schema limpio) + seed.
 * - Siguientes : trunca tablas + reseed (sin reconectar).
 *
 * @returns {Promise<import("express").Express>}
 */
export async function buildTestApp() {
  if (!_initialized) {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
    await AppDataSource.initialize();
    passportJwtSetup();
    await createInitialData();
    _initialized = true;

    process.on("beforeExit", async () => {
      if (AppDataSource.isInitialized) {
        await AppDataSource.destroy();
      }
    });
  } else {
    await resetDatabase();
  }

  const app = express();

  app.disable("x-powered-by");
  app.set("trust proxy", true);

  app.use(cors({ credentials: true, origin: true }));
  app.use(urlencoded({ extended: true, limit: "5mb" }));
  app.use(json({ limit: "10mb" }));
  app.use(cookieParser());

  app.use(
    session({
      secret: cookieKey || "test-secret-fallback",
      resave: false,
      saveUninitialized: false,
      cookie: { secure: false, httpOnly: true, sameSite: "strict" },
    }),
  );

  app.use(passport.initialize());
  app.use(passport.session());

  app.use("/api", indexRoutes);

  return app;
}

export { AppDataSource };
