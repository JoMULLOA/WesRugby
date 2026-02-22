import { describe, it, expect, vi } from "vitest";

// Mock de configEnv para evitar depender de la BD/config real
vi.mock("../../src/config/configEnv.js", () => ({
  HOST: "localhost",
  PORT: 3000,
  NODE_ENV: "test",
}));

const { resolveFileUrl } = await import("../../src/utils/storage.utils.js");

describe("resolveFileUrl", () => {
  const mockReq = {
    protocol: "http",
    get: (header) => (header === "host" ? "localhost:3000" : null),
  };

  it("retorna null si value es null", () => {
    expect(resolveFileUrl(null, mockReq)).toBeNull();
  });

  it("retorna null si value es undefined", () => {
    expect(resolveFileUrl(undefined, mockReq)).toBeNull();
  });

  it("retorna null si value es string vacío", () => {
    expect(resolveFileUrl("", mockReq)).toBeNull();
  });

  it("retorna la URL tal cual si ya es http://", () => {
    const url = "http://cdn.example.com/imagen.png";
    expect(resolveFileUrl(url, mockReq)).toBe(url);
  });

  it("retorna la URL tal cual si ya es https://", () => {
    const url = "https://cdn.example.com/foto.jpg";
    expect(resolveFileUrl(url, mockReq)).toBe(url);
  });

  it("construye URL completa para ruta relativa sin 'uploads/'", () => {
    const result = resolveFileUrl("avatars/foto.jpg", mockReq);
    expect(result).toBe("http://localhost:3000/uploads/avatars/foto.jpg");
  });

  it("construye URL completa para ruta que empieza con 'uploads/'", () => {
    const result = resolveFileUrl("uploads/avatars/foto.jpg", mockReq);
    expect(result).toBe("http://localhost:3000/uploads/avatars/foto.jpg");
  });

  it("elimina barras iniciales del path", () => {
    const result = resolveFileUrl("/avatars/foto.jpg", mockReq);
    expect(result).toBe("http://localhost:3000/uploads/avatars/foto.jpg");
  });

  it("usa protocolo https cuando el request lo indica", () => {
    const httpsReq = {
      protocol: "https",
      get: () => "wesrugby.site",
    };
    const result = resolveFileUrl("avatars/foto.jpg", httpsReq);
    expect(result).toContain("https://");
  });

  it("usa BACKEND_URL de env si está definida", () => {
    process.env.BACKEND_URL = "https://mock-backend.com";
    const result = resolveFileUrl("avatars/foto.jpg", mockReq);
    expect(result).toContain("mock-backend.com");
    delete process.env.BACKEND_URL;
  });

  it("no duplica '/uploads/' si la ruta ya lo contiene", () => {
    const result = resolveFileUrl("uploads/avatars/foto.jpg", mockReq);
    const count = (result.match(/uploads/g) || []).length;
    expect(count).toBe(1);
  });
});
