"use strict";
/**
 * auth.integration.test.js — Pruebas de integración para /api/auth
 *
 * Cubre los endpoints:
 *   POST /api/auth/login
 *   GET  /api/auth/profile
 *   POST /api/auth/logout
 *   POST /api/auth/register-apoderado
 *
 * La base de datos se inicializa con dropSchema:true antes de cada suite
 * (gracias a buildTestApp), lo que garantiza un estado limpio.
 * Los usuarios vienen del seed de createInitialData() en initialSetup.js.
 *
 * Credenciales sembradas disponibles:
 *   directiva@wessex.cl  / Directiva2024   (rol: directiva)
 *   tesorera@wessex.cl   / Tesorera2024    (rol: tesorera)
 *   entrenador@wessex.cl / Entrenador2024  (rol: entrenador)
 */

import { describe, it, expect, beforeAll } from "vitest";
import request from "supertest";
import { buildTestApp } from "./setup/testApp.js";

let app;

// ─── Setup global ────────────────────────────────────────────────────────────

beforeAll(async () => {
  // Inicializa DB (drop + recreate + seed) y construye el Express app
  app = await buildTestApp();
}, 60_000);

// La conexión la gestiona globalSetup.js (se destruye al terminar toda la suite)
// No cerramos el DataSource aquí para que inventory.integration.test.js lo reutilice.

// ─── POST /api/auth/login ─────────────────────────────────────────────────────

describe("POST /api/auth/login", () => {
  it("retorna 200 y un JWT cuando las credenciales son válidas", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "directiva@wessex.cl", password: "Directiva2024" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("token");
    expect(typeof res.body.data.token).toBe("string");
    expect(res.body.data.token.split(".")).toHaveLength(3); // JWT tiene 3 partes
  });

  it("el payload del token contiene los campos esperados del usuario", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "directiva@wessex.cl", password: "Directiva2024" });

    expect(res.body.data.user).toMatchObject({
      email: "directiva@wessex.cl",
      rol: "directiva",
    });
    expect(res.body.data.user).toHaveProperty("nombreCompleto");
    expect(res.body.data.user).toHaveProperty("rut");
  });

  it("retorna 400 cuando la contraseña es incorrecta", async () => {
    const res = await request(app).post("/api/auth/login").send({
      email: "directiva@wessex.cl",
      password: "contraseña_incorrecta",
    });

    expect(res.status).toBe(400);
  });

  it("retorna 400 cuando el email no existe en el sistema", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "fantasma@wessex.cl", password: "Directiva2024" });

    expect(res.status).toBe(400);
  });

  it("retorna 400 cuando falta la contraseña en el body", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "directiva@wessex.cl" });

    expect(res.status).toBe(400);
  });

  it("retorna 400 cuando el body está vacío", async () => {
    const res = await request(app).post("/api/auth/login").send({});

    expect(res.status).toBe(400);
  });

  it("puede autenticarse con diferentes roles (tesorera)", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "tesorera@wessex.cl", password: "Tesorera2024" });

    expect(res.status).toBe(200);
    expect(res.body.data.user).toHaveProperty("rol", "tesorera");
  });
});

// ─── GET /api/auth/profile ────────────────────────────────────────────────────

describe("GET /api/auth/profile", () => {
  let validToken;

  beforeAll(async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "directiva@wessex.cl", password: "Directiva2024" });
    validToken = res.body.data?.token;
  });

  it("retorna 401 cuando no se envía ningún token", async () => {
    const res = await request(app).get("/api/auth/profile");
    expect(res.status).toBe(401);
  });

  it("retorna 401 con un token malformado", async () => {
    const res = await request(app)
      .get("/api/auth/profile")
      .set("Authorization", "Bearer token.invalido.aqui");

    expect(res.status).toBe(401);
  });

  it("retorna 200 con el perfil correcto usando un token válido", async () => {
    const res = await request(app)
      .get("/api/auth/profile")
      .set("Authorization", `Bearer ${validToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({
      email: "directiva@wessex.cl",
      rol: "directiva",
    });
    expect(res.body.data).toHaveProperty("rut");
    expect(res.body.data).toHaveProperty("nombreCompleto");
  });
});

// ─── POST /api/auth/logout ────────────────────────────────────────────────────

describe("POST /api/auth/logout", () => {
  let validToken;

  beforeAll(async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "entrenador@wessex.cl", password: "Entrenador2024" });
    validToken = res.body.data?.token;
  });

  it("retorna 401 si se intenta hacer logout sin token", async () => {
    const res = await request(app).post("/api/auth/logout");
    expect(res.status).toBe(401);
  });

  it("retorna 200 al hacer logout con token válido", async () => {
    const res = await request(app)
      .post("/api/auth/logout")
      .set("Authorization", `Bearer ${validToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

// ─── POST /api/auth/register-apoderado ───────────────────────────────────────

describe("POST /api/auth/register-apoderado", () => {
  it("retorna 201 al registrar un apoderado con datos válidos", async () => {
    const res = await request(app).post("/api/auth/register-apoderado").send({
      // RUT válido: máx 29.999.999, con puntos y check digit en [0-9kK]
      rut: "12.999.001-K",
      nombreCompleto: "Apoderado Test Integration",
      email: "apoderado.test.integration@wessex.cl",
      password: "Password123",
      rol: "apoderado",
    });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });

  it("retorna 400 al intentar registrar con un email ya existente", async () => {
    // El mismo email del seed
    const res = await request(app).post("/api/auth/register-apoderado").send({
      rut: "11.111.111-1",
      nombreCompleto: "Duplicado",
      email: "directiva@wessex.cl",
      password: "Password123",
      rol: "apoderado",
    });

    expect(res.status).toBe(400);
  });

  it("retorna 400 si faltan campos obligatorios", async () => {
    const res = await request(app)
      .post("/api/auth/register-apoderado")
      .send({ email: "incompleto@test.cl" });

    expect(res.status).toBe(400);
  });
});
