import { describe, it, expect } from "vitest";
import {
  encryptPassword,
  comparePassword,
} from "../../src/helpers/bcrypt.helper.js";

describe("encryptPassword", () => {
  it("genera un hash distinto a la contraseña original", async () => {
    const plain = "MiPassword123";
    const hash = await encryptPassword(plain);
    expect(hash).not.toBe(plain);
  });

  it("el hash tiene el formato bcrypt ($2b$)", async () => {
    const hash = await encryptPassword("cualquier_clave");
    expect(hash).toMatch(/^\$2[ab]\$/);
  });

  it("dos llamadas con la misma clave generan hashes distintos (salt único)", async () => {
    const plain = "RepetidaClave99";
    const hash1 = await encryptPassword(plain);
    const hash2 = await encryptPassword(plain);
    expect(hash1).not.toBe(hash2);
  });

  it("el hash tiene una longitud de 60 caracteres", async () => {
    const hash = await encryptPassword("Test1234");
    expect(hash).toHaveLength(60);
  });
});

describe("comparePassword", () => {
  it("retorna true cuando la contraseña coincide con el hash", async () => {
    const plain = "ClaveCorrecta123";
    const hash = await encryptPassword(plain);
    const result = await comparePassword(plain, hash);
    expect(result).toBe(true);
  });

  it("retorna false cuando la contraseña NO coincide", async () => {
    const hash = await encryptPassword("ClaveReal456");
    const result = await comparePassword("ClaveIncorrecta", hash);
    expect(result).toBe(false);
  });

  it("es case-sensitive (mayúsculas vs minúsculas)", async () => {
    const hash = await encryptPassword("ClaveConMayuscula");
    const result = await comparePassword("claveconymayuscula", hash);
    expect(result).toBe(false);
  });

  it("retorna false con contraseña vacía", async () => {
    const hash = await encryptPassword("ClaveLarga123");
    const result = await comparePassword("", hash);
    expect(result).toBe(false);
  });
});
