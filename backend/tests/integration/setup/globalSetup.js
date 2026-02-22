"use strict";
/**
 * globalSetup.js — Se ejecuta UNA SOLA VEZ antes de todos los archivos de test.
 *
 * Vitest llama a la función `setup` exportada antes de lanzar cualquier
 * archivo de integración, y `teardown` (el callback que retorna) al terminar todo.
 *
 * Ventaja: el DataSource de TypeORM se inicializa una vez y permanece
 * abierto durante toda la suite. Los archivos individuales ya NO necesitan
 * reconectarse ni destruir — solo resembrar datos limpios.
 */

import { AppDataSource } from "../../../src/config/configDb.js";
import { passportJwtSetup } from "../../../src/auth/passport.auth.js";

export async function setup() {
  // TypeORM con dropSchema:true elimina y recrea todas las tablas.
  // Solo necesitamos hacer esto una vez para toda la suite.
  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
    console.log("\n[globalSetup] ✅ Base de datos inicializada para integración");
  }

  // Registrar estrategia JWT en Passport (idempotente)
  passportJwtSetup();

  // Devolver teardown: se ejecuta cuando todos los archivos terminan
  return async () => {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
      console.log("\n[globalSetup] 🔌 Conexión a BD cerrada");
    }
  };
}
