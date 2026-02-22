import { config as loadEnv } from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const currentFile = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFile);
const envFile = path.resolve(currentDir, ".env");

// Solo cargar archivo .env si existe y no estamos en producción con variables de entorno configuradas
// En Docker, las variables vienen del entorno y no necesitamos el archivo
if (fs.existsSync(envFile) && !process.env.IS_DOCKER) {
  loadEnv({ path: envFile });
  console.log("📄 Cargando configuración desde archivo .env local");
} else {
  console.log("🐳 Usando variables de entorno del sistema (Docker/producción)");
}

const env = process.env;

const parseNumber = (value, fallback) => {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const parseBoolean = (value, fallback = false) => {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (["1", "true", "yes", "y"].includes(normalized)) {
      return true;
    }
    if (["0", "false", "no", "n"].includes(normalized)) {
      return false;
    }
  }
  return fallback;
};

export const NODE_ENV = env.NODE_ENV ?? "development";
export const HOST = env.HOST?.trim() || "127.0.0.1";
export const PORT = parseNumber(env.PORT, 3000);

export const DB_HOST = env.DB_HOST?.trim() || HOST;
export const DB_PORT = parseNumber(env.DB_PORT, 5432);
export const DB_USERNAME = env.DB_USERNAME?.trim() || "postgres";
export const PASSWORD = env.PASSWORD ?? "";
export const DATABASE = env.DATABASE?.trim() || "postgres";
export const DATABASE_URL = env.DATABASE_URL;
export const DB_SSL = parseBoolean(env.DB_SSL, false);

export const ACCESS_TOKEN_SECRET = env.ACCESS_TOKEN_SECRET;
export const cookieKey = env.cookieKey;
export const COOKIE_KEY = cookieKey;

export const EMAIL_HOST = env.EMAIL_HOST;
export const EMAIL_PORT = parseNumber(env.EMAIL_PORT, 587);
export const EMAIL_USER = env.EMAIL_USER;
export const EMAIL_PASS = env.EMAIL_PASS;

export const SMTP_CONFIG = {
  host: EMAIL_HOST,
  port: EMAIL_PORT,
  secure: EMAIL_PORT === 465,
  auth:
    EMAIL_USER && EMAIL_PASS
      ? { user: EMAIL_USER, pass: EMAIL_PASS }
      : undefined,
};

export const APP_CONFIG = {
  env: NODE_ENV,
  host: HOST,
  port: PORT,
  cookieSecret: COOKIE_KEY,
};

export const DATABASE_CONFIG = {
  url: DATABASE_URL,
  host: DB_HOST,
  port: DB_PORT,
  username: DB_USERNAME,
  password: PASSWORD,
  database: DATABASE,
  ssl: DB_SSL,
};
