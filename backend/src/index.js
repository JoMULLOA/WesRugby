"use strict";
import cors from "cors";
import morgan from "morgan";
import cookieParser from "cookie-parser";
import session from "express-session";
import passport from "passport";
import express, { json, urlencoded } from "express";
import cron from "node-cron";
import http from "http";
import 'dotenv/config';
import indexRoutes from "./routes/index.routes.js";
// Socket.io removido - no necesario para WesRugby 
import { cookieKey, HOST, PORT } from "./config/configEnv.js";
import { connectDB } from "./config/configDb.js";
import { createInitialData } from "./config/initialSetup.js";
import { passportJwtSetup } from "./auth/passport.auth.js";



async function setupServer() {
  try {
    const app = express();

    app.disable("x-powered-by");

    // Middleware de configuración
    app.use(cors({
      credentials: true,
      origin: true,
    }));

    app.use(urlencoded({
      extended: true,
      limit: "1mb",
    }));

    app.use(json({
      limit: "1mb",
    }));

    app.use(cookieParser());
    app.use(morgan("dev"));

    app.use(session({
      secret: cookieKey,
      resave: false,
      saveUninitialized: false,
      cookie: {
        secure: false,
        httpOnly: true,
        sameSite: "strict",
      },
    }));

    // Inicialización de Passport para autenticación
    app.use(passport.initialize());
    app.use(passport.session());
    
    // Registro de rutas
    app.use("/api", indexRoutes);

    // Inicio del servidor HTTP básico
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Corriendo en ${HOST}:${PORT}/api`);
    });
  } catch (error) {
    console.error("Error en index.js -> setupServer():", error);
  }
}

async function setupAPI() {
  try {
    await connectDB();            // Postgres 
    
    // Configurar Passport después de que la base de datos esté conectada
    passportJwtSetup();
    
    await setupServer();
    await createInitialData();
  } catch (error) {
    console.error("Error en index.js -> setupAPI():", error);
  }
}

setupAPI()
  .then(() => console.log("=> API Iniciada exitosamente"))
  .catch((error) => console.error("Error al iniciar la API:", error));