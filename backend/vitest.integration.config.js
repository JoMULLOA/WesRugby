import { defineConfig } from "vitest/config";

/**
 * Configuración de Vitest exclusiva para pruebas de INTEGRACIÓN.
 *
 * Diferencias clave respecto a vitest.config.js (unit):
 *  - fileParallelism: false → los archivos corren en serie para evitar
 *    conflictos en la base de datos (cada archivo llama connectDB() que
 *    hace dropSchema + recreate, por eso no pueden correr en paralelo).
 *  - testTimeout / hookTimeout más altos → las operaciones de BD requieren
 *    más tiempo que los mocks en memoria.
 *  - Solo incluye la carpeta tests/integration/
 */
export default defineConfig({
  test: {
    globals: true,
    environment: "node",

    // ⚠️ CRÍTICO: no ejecutar archivos en paralelo.
    // Dos archivos conectando simultáneamente al mismo AppDataSource
    // (con dropSchema:true) corromperían los datos mutuamente.
    fileParallelism: false,

    // Tiempo máximo por test individual (ms)
    testTimeout: 30_000,

    // Tiempo máximo para hooks beforeAll / afterAll (ms)
    hookTimeout: 60_000,

    // Solo los tests de integración
    include: ["tests/integration/**/*.test.js"],

    // Sin coverage en integración (ya lo hacen los unit tests)
    coverage: {
      enabled: false,
    },
  },
});
