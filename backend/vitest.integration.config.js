import { defineConfig } from "vitest/config";

/**
 * Configuración de Vitest exclusiva para pruebas de INTEGRACIÓN.
 *
 * Arquitectura de aislamiento:
 *  - pool:forks + singleFork:true : todos los archivos de test se ejecutan
 *    en el MISMO proceso hijo de Node.js. El módulo testApp.js y su flag
 *    `_initialized` son compartidos entre archivos gracias a la caché de
 *    módulos de Node. TypeORM se inicializa UNA SOLA VEZ (primer archivo)
 *    y los siguientes solo truncan tablas y resemillan datos.
 *  - fileParallelism:false : los archivos corren en serie (sin carreras de BD).
 *  - Sin globalSetup: globalSetup corre en el proceso PRINCIPAL de Vitest,
 *    diferente al fork de tests → no puede compartir singletons de TypeORM.
 */
export default defineConfig({
  test: {
    globals: true,
    environment: "node",

    // Todos los archivos en el mismo proceso hijo → módulo _initialized compartido
    pool: "forks",
    poolOptions: {
      forks: {
        singleFork: true,
      },
    },

    // En serie: evitar que dos archivos hagan TRUNCATE simultáneamente
    fileParallelism: false,

    // Tiempo máximo por test individual (ms)
    testTimeout: 30_000,

    // Tiempo máximo para hooks beforeAll / afterAll (ms)
    hookTimeout: 60_000,

    // Solo los tests de integración
    include: ["tests/integration/**/*.test.js"],

    coverage: {
      enabled: false,
    },
  },
});
