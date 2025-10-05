import path from "path";
import { fileURLToPath } from "url";
import { DataSource } from "typeorm";
import { DATABASE_CONFIG, NODE_ENV } from "./configEnv.js";

const currentFile = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFile);
const projectRoot = path.resolve(currentDir, "..");

const buildGlob = (relativePattern) => path.join(projectRoot, relativePattern);

const isTestEnv = NODE_ENV === "test";

const commonOptions = {
  entities: [buildGlob("entity/**/*.js")],
  migrations: [buildGlob("migrations/**/*.js")],
  migrationsRun: true,
  logging: NODE_ENV === "development",
  synchronize: false,
};

let dataSourceOptions;

if (isTestEnv) {
  dataSourceOptions = {
    type: "sqlite",
    database: ":memory:",
    ...commonOptions,
  };
} else if (DATABASE_CONFIG.url) {
  dataSourceOptions = {
    type: "postgres",
    url: DATABASE_CONFIG.url,
    ssl: DATABASE_CONFIG.ssl ? { rejectUnauthorized: false } : false,
    ...commonOptions,
  };
} else {
  dataSourceOptions = {
    type: "postgres",
    host: DATABASE_CONFIG.host,
    port: DATABASE_CONFIG.port,
    username: DATABASE_CONFIG.username,
    password: DATABASE_CONFIG.password,
    database: DATABASE_CONFIG.database,
    ssl: DATABASE_CONFIG.ssl ? { rejectUnauthorized: false } : false,
    ...commonOptions,
  };
}

export const AppDataSource = new DataSource(dataSourceOptions);

export async function connectDB() {
  if (AppDataSource.isInitialized) {
    return AppDataSource;
  }

  try {
    await AppDataSource.initialize();
    return AppDataSource;
  } catch (error) {
    console.error("Failed to initialize database connection", error);
    throw error;
  }
}