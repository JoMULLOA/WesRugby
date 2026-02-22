import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/*.test.js", "tests/**/*.test.js"],
    // Excluir integration tests: tienen su propio config (vitest.integration.config.js)
    // y necesitan fileParallelism:false + BD real. Si se incluyen aquí corren en
    // paralelo y se corrompen mutuamente (dropSchema en simultáneo).
    exclude: ["tests/integration/**"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html"],
      include: ["src/**/*.js"],
      exclude: [
        "src/index.js",
        "src/config/**",
        "src/entity/**",
        "src/migrations/**",
      ],
    },
  },
});
