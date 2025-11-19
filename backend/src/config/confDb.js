"use strict";

import { DataSource } from "typeorm";
import {
  DATABASE,
  DB_USERNAME,
  HOST,
  PASSWORD
} from "./configEnv.js";

export const AppDataSource = new DataSource({
  type: "postgres",
  host: HOST,
  port: 5432,
  username: DB_USERNAME,
  password: PASSWORD,
  database: DATABASE,

  // Ruta correcta a tus entidades
  entities: ["src/entity/**/*.js"],

  synchronize: true,
  dropSchema: true,
  logging: false,
  ssl: {
    rejectUnauthorized: false
  },

  extra: {
    charset: "utf8mb4"
  }
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
