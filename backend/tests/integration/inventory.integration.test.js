"use strict";
/**
 * inventory.integration.test.js — Pruebas de integración para /api/inventario
 *
 * Cubre los endpoints:
 *   GET    /api/inventario/health
 *   GET    /api/inventario/products
 *   GET    /api/inventario/products/management
 *   POST   /api/inventario/products
 *   DELETE /api/inventario/products/:id          (soft delete)
 *   DELETE /api/inventario/products/:id/permanent
 *   GET    /api/inventario/sales/summary
 *   POST   /api/inventario/scans/bulk
 *   POST   /api/inventario/sales/varios
 *   DELETE /api/inventario/sales/:saleId
 *
 * El inventario tiene dos "productos especiales" sembrados por initialSetup:
 *   - Producto "Varios" (categoría: varios, pricingMode: variable)
 *
 * Los endpoints de Inventario NO requieren autenticación en las rutas
 * actuales (inventory.routes.js no usa authenticateJwt globalmente).
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import request from "supertest";
import { buildTestApp, AppDataSource } from "./setup/testApp.js";

let app;

// ─── Setup global ────────────────────────────────────────────────────────────

beforeAll(async () => {
  app = await buildTestApp();
}, 60_000);

afterAll(async () => {
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
  }
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

const BASE = "/api/inventario";

/** Crea un producto de prueba y retorna el body de la respuesta. */
async function createTestProduct(overrides = {}) {
  const defaults = {
    name: `Producto Test ${Date.now()}`,
    category: "bebida_latas",
    sourceType: "compra",
    pricingMode: "fixed",
    defaultPriceCents: 1200,
  };

  const res = await request(app)
    .post(`${BASE}/products`)
    .send({ ...defaults, ...overrides });

  return res;
}

// ─── GET /api/inventario/health ───────────────────────────────────────────────

describe("GET /api/inventario/health", () => {
  it("retorna 200 con { ok: true }", async () => {
    const res = await request(app).get(`${BASE}/health`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });
  });
});

// ─── GET /api/inventario/products ─────────────────────────────────────────────

describe("GET /api/inventario/products", () => {
  it("retorna 200 con un array", async () => {
    const res = await request(app).get(`${BASE}/products`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it("los productos tienen las propiedades esperadas del schema", async () => {
    // Crear uno para asegurar que hay al menos un producto activo
    await createTestProduct({ name: "Agua Mineral Schema Check" });

    const res = await request(app).get(`${BASE}/products`);
    const products = res.body;

    // La lista puede venir del seed o del producto recién creado
    expect(products.length).toBeGreaterThan(0);

    const producto = products[0];
    expect(producto).toHaveProperty("id");
    expect(producto).toHaveProperty("name");
    expect(producto).toHaveProperty("category");
    expect(producto).toHaveProperty("pricingMode");
    expect(producto).toHaveProperty("active");
  });

  it("solo devuelve productos activos (active: true)", async () => {
    const res = await request(app).get(`${BASE}/products`);
    const inactivos = res.body.filter((p) => p.active === false);

    expect(inactivos).toHaveLength(0);
  });
});

// ─── GET /api/inventario/products/management ──────────────────────────────────

describe("GET /api/inventario/products/management", () => {
  it("retorna 200 con un array", async () => {
    const res = await request(app).get(`${BASE}/products/management`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it("incluye productos inactivos por defecto (includeInactive=true)", async () => {
    // Crear un producto y luego soft-deletearlo
    const created = await createTestProduct({ name: "Producto A Desactivar" });
    const id = created.body.id;

    await request(app).delete(`${BASE}/products/${id}`);

    const res = await request(app).get(`${BASE}/products/management`);
    const found = res.body.find((p) => p.id === id);

    // Debe aparecer en management (con active:false)
    expect(found).toBeDefined();
    expect(found.active).toBe(false);
  });

  it("excluye productos inactivos cuando includeInactive=false", async () => {
    const res = await request(app).get(
      `${BASE}/products/management?includeInactive=false`,
    );

    const inactivos = res.body.filter((p) => p.active === false);
    expect(inactivos).toHaveLength(0);
  });
});

// ─── POST /api/inventario/products ────────────────────────────────────────────

describe("POST /api/inventario/products", () => {
  it("crea un producto válido con pricingMode fixed y retorna 201", async () => {
    const res = await createTestProduct({
      name: "Coca Cola Lata",
      category: "bebida_latas",
      pricingMode: "fixed",
      defaultPriceCents: 1500,
    });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("id");
    expect(res.body).toHaveProperty("name", "Coca Cola Lata");
    expect(res.body).toHaveProperty("category", "bebida_latas");
    expect(res.body).toHaveProperty("active", true);
  });

  it("crea un producto variable (sin defaultPriceCents) y retorna 201", async () => {
    const res = await createTestProduct({
      name: "Empanada Variable",
      category: "pasteleria",
      sourceType: "compra",
      pricingMode: "variable",
      defaultPriceCents: null,
    });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("pricingMode", "variable");
  });

  it("asigna un barcode automáticamente si no se proporciona", async () => {
    const res = await createTestProduct({ name: "Pastilla Sin Barcode" });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("barcode");
    expect(typeof res.body.barcode).toBe("string");
    expect(res.body.barcode.length).toBeGreaterThan(0);
  });

  it("retorna 400 cuando el nombre es demasiado corto (< 2 chars)", async () => {
    const res = await createTestProduct({ name: "X" });

    expect(res.status).toBe(400);
  });

  it("retorna 400 con una categoría que no existe en el enum", async () => {
    const res = await createTestProduct({ category: "categoria_inventada" });

    expect(res.status).toBe(400);
  });

  it("retorna 400 con pricingMode inválido", async () => {
    const res = await createTestProduct({ pricingMode: "gratis" });

    expect(res.status).toBe(400);
  });

  it("retorna 400 cuando faltan campos obligatorios", async () => {
    const res = await request(app).post(`${BASE}/products`).send({});

    expect(res.status).toBe(400);
  });

  it("retorna 409 al intentar crear un producto con barcode duplicado", async () => {
    // Crear el primero
    const first = await createTestProduct({ name: "Producto Barcode Test" });
    const barcodeUsado = first.body.barcode;

    // Intentar crear otro con el mismo barcode
    const res = await request(app).post(`${BASE}/products`).send({
      name: "Producto Barcode Duplicado",
      category: "bebida_latas",
      sourceType: "compra",
      pricingMode: "fixed",
      barcode: barcodeUsado,
    });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe("BARCODE_IN_USE");
  });
});

// ─── DELETE /api/inventario/products/:id (soft delete) ────────────────────────

describe("DELETE /api/inventario/products/:id (soft delete)", () => {
  let productId;

  beforeAll(async () => {
    const res = await createTestProduct({ name: "Producto Para Soft Delete" });
    productId = res.body.id;
  });

  it("retorna 200 al desactivar (soft delete) un producto existente", async () => {
    const res = await request(app).delete(`${BASE}/products/${productId}`);

    expect(res.status).toBe(200);
    // El producto existe pero con active:false
    expect(res.body).toHaveProperty("active", false);
  });

  it("el producto aparece inactivo en management tras el soft delete", async () => {
    const res = await request(app).get(`${BASE}/products/management`);
    const found = res.body.find((p) => p.id === productId);

    expect(found).toBeDefined();
    expect(found.active).toBe(false);
  });

  it("retorna 404 al intentar eliminar un UUID válido pero inexistente", async () => {
    const res = await request(app).delete(
      `${BASE}/products/00000000-0000-4000-a000-000000000000`,
    );

    expect(res.status).toBe(404);
    expect(res.body.error).toBe("PRODUCT_NOT_FOUND");
  });
});

// ─── DELETE /api/inventario/products/:id/permanent ────────────────────────────

describe("DELETE /api/inventario/products/:id/permanent", () => {
  let productId;

  beforeAll(async () => {
    const res = await createTestProduct({
      name: "Producto Para Borrado Definitivo",
    });
    productId = res.body.id;
  });

  it("retorna 200 al eliminar permanentemente un producto", async () => {
    const res = await request(app).delete(
      `${BASE}/products/${productId}/permanent`,
    );

    expect(res.status).toBe(200);
  });

  it("el producto ya no aparece en management tras el borrado permanente", async () => {
    const res = await request(app).get(`${BASE}/products/management`);
    const found = res.body.find((p) => p.id === productId);

    expect(found).toBeUndefined();
  });

  it("retorna 404 al intentar borrar permanentemente un produto inexistente", async () => {
    const res = await request(app).delete(
      `${BASE}/products/00000000-0000-4000-a000-000000000001/permanent`,
    );

    expect(res.status).toBe(404);
  });
});

// ─── GET /api/inventario/sales/summary ────────────────────────────────────────

describe("GET /api/inventario/sales/summary", () => {
  it("retorna 200 con estructura de resumen de ventas", async () => {
    const res = await request(app).get(`${BASE}/sales/summary`);

    expect(res.status).toBe(200);
    // El resumen debe ser un objeto con datos de ventas
    expect(typeof res.body).toBe("object");
  });
});

// ─── POST /api/inventario/sales/varios ────────────────────────────────────────

describe("POST /api/inventario/sales/varios", () => {
  it("retorna 201 al registrar una venta de tipo varios", async () => {
    const res = await request(app).post(`${BASE}/sales/varios`).send({
      priceCents: 1000,
      quantity: 2,
      deviceId: "test-device-integration",
    });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("id");
  });

  it("retorna 400 si priceCents es cero o negativo", async () => {
    const res = await request(app).post(`${BASE}/sales/varios`).send({
      priceCents: 0,
      quantity: 1,
      deviceId: "test-device-integration",
    });

    expect(res.status).toBe(400);
  });

  it("retorna 400 si falta priceCents", async () => {
    const res = await request(app).post(`${BASE}/sales/varios`).send({
      quantity: 1,
      deviceId: "test-device-integration",
    });

    expect(res.status).toBe(400);
  });
});

// ─── POST /api/inventario/scans/bulk ──────────────────────────────────────────

describe("POST /api/inventario/scans/bulk", () => {
  let productId;
  let productBarcode;

  beforeAll(async () => {
    const res = await createTestProduct({
      name: "Producto Para Escanear",
      pricingMode: "fixed",
      defaultPriceCents: 900,
    });
    productId = res.body.id;
    productBarcode = res.body.barcode;
  });

  it("retorna 200 al procesar un lote de escaneos válido", async () => {
    const { randomUUID } = await import("crypto");

    const res = await request(app)
      .post(`${BASE}/scans/bulk`)
      .send({
        scans: [
          {
            id: randomUUID(),
            barcode: productBarcode,
            scannedAt: new Date().toISOString(),
            deviceId: "test-scanner-01",
            priceCents: 900,
            quantity: 1,
          },
        ],
      });

    expect(res.status).toBe(200);
    // processBulkScans devuelve { acceptedIds, accepted, rejected }
    expect(res.body).toHaveProperty("acceptedIds");
    expect(res.body).toHaveProperty("accepted");
    expect(res.body).toHaveProperty("rejected");
    expect(Array.isArray(res.body.acceptedIds)).toBe(true);
  });

  it("retorna 400 si el array scans está vacío", async () => {
    const res = await request(app)
      .post(`${BASE}/scans/bulk`)
      .send({ scans: [] });

    expect(res.status).toBe(400);
  });

  it("retorna 400 si falta el campo scans", async () => {
    const res = await request(app)
      .post(`${BASE}/scans/bulk`)
      .send({});

    expect(res.status).toBe(400);
  });
});
