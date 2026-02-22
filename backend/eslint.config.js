// eslint.config.js — Formato flat config requerido por ESLint 9.x
// (ESLint 9 eliminó el formato .eslintrc.* y requiere este archivo)
//
// eslint-config-google no es compatible con ESLint 9, así que usamos
// las reglas equivalentes directamente más eslint-plugin-prettier.

import js from "@eslint/js";
import prettierPlugin from "eslint-plugin-prettier";
import prettierConfig from "eslint-config-prettier";

export default [
  // Reglas base recomendadas de ESLint
  js.configs.recommended,

  // Deshabilitar reglas de ESLint que entran en conflicto con Prettier
  prettierConfig,

  {
    // Aplicar a todos los archivos JS del backend
    files: ["**/*.js"],

    plugins: {
      prettier: prettierPlugin,
    },

    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        // Node.js globals
        process: "readonly",
        console: "readonly",
        __dirname: "readonly",
        __filename: "readonly",
        Buffer: "readonly",
        setTimeout: "readonly",
        clearTimeout: "readonly",
        setInterval: "readonly",
        clearInterval: "readonly",
        URL: "readonly",
        URLSearchParams: "readonly",
      },
    },

    rules: {
      // Prettier formatea el código; ESLint reporta diferencias como errores
      "prettier/prettier": "warn",

      // Buenas prácticas básicas
      "no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_|^next$|^req$|^res$",
          varsIgnorePattern: "^_",
          destructuredArrayIgnorePattern: "^_",
          ignoreRestSiblings: true,
        },
      ],
      "no-console": "off", // El backend usa console.log/error extensamente
      "no-undef": "error",
      "prefer-const": "warn",
      "no-var": "error",
    },
  },

  {
    // Ignorar carpetas que no son código fuente propio
    ignores: [
      "node_modules/**",
      "coverage/**",
      "uploads/**",
      "migrations/**",
      "dist/**",
    ],
  },
];
