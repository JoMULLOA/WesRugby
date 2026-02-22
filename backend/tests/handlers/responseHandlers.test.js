import { describe, it, expect, vi } from "vitest";
import {
  handleSuccess,
  handleErrorClient,
  handleErrorServer,
} from "../../src/handlers/responseHandlers.js";

// Helper para crear un mock de res
function mockRes() {
  const res = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}

describe("handleSuccess", () => {
  it("responde con statusCode y mensaje correcto", () => {
    const res = mockRes();
    handleSuccess(res, 200, "Operación exitosa");
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Operación exitosa",
    });
  });

  it("incluye data cuando se proporciona", () => {
    const res = mockRes();
    const data = { id: 1, nombre: "Test" };
    handleSuccess(res, 201, "Creado", data);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: "Creado",
      data,
    });
  });

  it("NO incluye data cuando es null", () => {
    const res = mockRes();
    handleSuccess(res, 200, "OK", null);
    const called = res.json.mock.calls[0][0];
    expect(called).not.toHaveProperty("data");
  });

  it("NO incluye data cuando es undefined", () => {
    const res = mockRes();
    handleSuccess(res, 200, "OK");
    const called = res.json.mock.calls[0][0];
    expect(called).not.toHaveProperty("data");
  });

  it("funciona con distintos códigos 2xx", () => {
    for (const code of [200, 201, 204]) {
      const res = mockRes();
      handleSuccess(res, code, "msg");
      expect(res.status).toHaveBeenCalledWith(code);
    }
  });
});

describe("handleErrorClient", () => {
  it("responde con status 'Client error' y detalles", () => {
    const res = mockRes();
    handleErrorClient(res, 400, "Error de validación", "campo requerido");
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      status: "Client error",
      message: "Error de validación",
      details: "campo requerido",
    });
  });

  it("usa objeto vacío como details por defecto", () => {
    const res = mockRes();
    handleErrorClient(res, 404, "No encontrado");
    const called = res.json.mock.calls[0][0];
    expect(called.details).toEqual({});
  });

  it("responde 401 para errores de autenticación", () => {
    const res = mockRes();
    handleErrorClient(res, 401, "No autorizado");
    expect(res.status).toHaveBeenCalledWith(401);
  });

  it("responde 403 para errores de autorización", () => {
    const res = mockRes();
    handleErrorClient(res, 403, "Sin permisos");
    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe("handleErrorServer", () => {
  it("responde con status 'Server error' y mensaje", () => {
    const res = mockRes();
    handleErrorServer(res, 500, "Error interno");
    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      status: "Server error",
      message: "Error interno",
    });
  });

  it("no incluye campos extra no esperados", () => {
    const res = mockRes();
    handleErrorServer(res, 500, "Fallo");
    const called = res.json.mock.calls[0][0];
    expect(Object.keys(called)).toEqual(["status", "message"]);
  });
});
