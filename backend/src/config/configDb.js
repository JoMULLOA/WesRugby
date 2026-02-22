"use strict";

import { DataSource } from "typeorm";
import { DATABASE, DB_HOST, DB_USERNAME, PASSWORD } from "./configEnv.js";

export const AppDataSource = new DataSource({
  type: "postgres",
  host: DB_HOST,
  port: 5432,
  username: DB_USERNAME,
  password: PASSWORD,
  database: DATABASE,

  // Ruta correcta a tus entidades
  entities: ["src/entity/**/*.js"],

  // Configuración de migraciones (solo archivos .js)
  migrations: ["migrations/**/*.js"],
  migrationsTableName: "migrations_history",

  synchronize: true,
  dropSchema: true,
  logging: false,
  ssl: false,

  extra: {
    // PostgreSQL usa 'client_encoding', no 'charset'
    client_encoding: "UTF8",
  },
});

export async function connectDB() {
  try {
    await AppDataSource.initialize();
    console.log("=> Conexión exitosa a la base de datos!");
  } catch (error) {
    console.error("Error al conectar con la base de datos:", error);
    process.exit(1);
  }
}
