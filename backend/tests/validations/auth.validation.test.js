import { describe, it, expect } from "vitest";
import {
  authValidation,
  registerValidation,
} from "../../src/validations/auth.validation.js";

// ──────────────────────────────────────────────
// authValidation (login)
// ──────────────────────────────────────────────
describe("authValidation (login)", () => {
  const validPayload = {
    email: "usuario@wessex.cl",
    password: "Clave1234",
  };

  it("acepta credenciales válidas", () => {
    const { error } = authValidation.validate(validPayload);
    expect(error).toBeUndefined();
  });

  it("acepta email de dominio @alumnos.ubiobio.cl", () => {
    const { error } = authValidation.validate({
      ...validPayload,
      email: "alumno123@alumnos.ubiobio.cl",
    });
    expect(error).toBeUndefined();
  });

  it("acepta email de dominio @ubiobio.cl", () => {
    const { error } = authValidation.validate({
      ...validPayload,
      email: "docente@ubiobio.cl",
    });
    expect(error).toBeUndefined();
  });

  it("rechaza email de dominio no permitido", () => {
    const { error } = authValidation.validate({
      ...validPayload,
      email: "usuario@gmail.com",
    });
    expect(error).toBeDefined();
  });

  it("rechaza email vacío", () => {
    const { error } = authValidation.validate({ ...validPayload, email: "" });
    expect(error).toBeDefined();
  });

  it("rechaza sin campo email", () => {
    const { error } = authValidation.validate({ password: "Clave1234" });
    expect(error).toBeDefined();
  });

  it("rechaza contraseña menor a 8 caracteres", () => {
    const { error } = authValidation.validate({
      ...validPayload,
      password: "corta",
    });
    expect(error).toBeDefined();
  });

  it("rechaza contraseña mayor a 26 caracteres", () => {
    const { error } = authValidation.validate({
      ...validPayload,
      password: "a".repeat(27),
    });
    expect(error).toBeDefined();
  });

  it("rechaza sin campo password", () => {
    const { error } = authValidation.validate({
      email: "usuario@wessex.cl",
    });
    expect(error).toBeDefined();
  });

  it("rechaza propiedades extra no permitidas", () => {
    const { error } = authValidation.validate({
      ...validPayload,
      campoExtra: "no permitido",
    });
    expect(error).toBeDefined();
  });
});

// ──────────────────────────────────────────────
// registerValidation
// ──────────────────────────────────────────────
describe("registerValidation", () => {
  const validPayload = {
    nombreCompleto: "Juan Pablo García",
    rut: "12.345.678-9",
    email: "juan.garcia@wessex.cl",
    rol: "apoderado",
    password: "Segura123",
  };

  it("acepta payload válido completo", () => {
    const { error } = registerValidation.validate(validPayload);
    expect(error).toBeUndefined();
  });

  it("acepta todos los roles válidos", () => {
    const roles = ["directiva", "tesorera", "apoderado", "entrenador"];
    for (const rol of roles) {
      const { error } = registerValidation.validate({ ...validPayload, rol });
      expect(error).toBeUndefined();
    }
  });

  it("rechaza rol inválido", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      rol: "administrador",
    });
    expect(error).toBeDefined();
  });

  it("rechaza nombre con números", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      nombreCompleto: "Juan123 Garcia",
    });
    expect(error).toBeDefined();
  });

  it("rechaza nombre menor a 10 caracteres", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      nombreCompleto: "Ana",
    });
    expect(error).toBeDefined();
  });

  it("rechaza RUT con formato incorrecto", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      rut: "12345678",
    });
    expect(error).toBeDefined();
  });

  it("acepta RUT formato 12.345.678-9", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      rut: "12.345.678-9",
    });
    expect(error).toBeUndefined();
  });

  it("acepta RUT formato 12345678-9 (sin puntos)", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      rut: "12345678-9",
    });
    expect(error).toBeUndefined();
  });

  it("rechaza contraseña con caracteres especiales", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      password: "Clave!@#123",
    });
    expect(error).toBeDefined();
  });

  it("rechaza contraseña menor a 8 caracteres", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      password: "abc",
    });
    expect(error).toBeDefined();
  });

  it("rechaza email de dominio no permitido", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      email: "usuario@hotmail.com",
    });
    expect(error).toBeDefined();
  });

  it("rechaza payload con campos extra", () => {
    const { error } = registerValidation.validate({
      ...validPayload,
      admin: true,
    });
    expect(error).toBeDefined();
  });
});
