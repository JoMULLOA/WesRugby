import { describe, it, expect } from "vitest";
import Joi from "joi";

// Esquemas replicados del controller (misma lógica, sin depender de la BD)
const INVENTORY_PRODUCT_CATEGORIES = [
  "bebida_latas", "pasteleria", "selladitos", "cafeteria",
  "pastillas", "papas_fritas_cajita", "bebidas_energeticas",
  "varios", "comestibles", "otros_productos",
];
const INVENTORY_SOURCE_TYPES = ["compra", "donacion"];
const INVENTORY_PRICING_MODES = ["fixed", "variable"];

const productSchema = Joi.object({
  id: Joi.string().uuid({ version: "uuidv4" }).optional(),
  name: Joi.string().min(2).max(200).required(),
  category: Joi.string().valid(...INVENTORY_PRODUCT_CATEGORIES).required(),
  sourceType: Joi.string().valid(...INVENTORY_SOURCE_TYPES).required(),
  pricingMode: Joi.string().valid(...INVENTORY_PRICING_MODES).required(),
  defaultPriceCents: Joi.number().integer().min(0).allow(null).optional(),
  barcode: Joi.string().min(6).max(40).optional(),
  active: Joi.boolean().optional(),
});

const scanSchema = Joi.object({
  id: Joi.string().uuid({ version: "uuidv4" }).required(),
  barcode: Joi.string().min(6).max(40).required(),
  scannedAt: Joi.date().iso().required(),
  deviceId: Joi.string().min(2).max(80).required(),
  priceCents: Joi.number().integer().min(0).optional(),
  quantity: Joi.number().integer().min(1).optional(),
});

const bulkSchema = Joi.object({
  scans: Joi.array().items(scanSchema).min(1).required(),
});

const variosSchema = Joi.object({
  priceCents: Joi.number().integer().min(1).required(),
  quantity: Joi.number().integer().min(1).optional(),
  deviceId: Joi.string().min(2).max(80).optional(),
});

// ──────────────────────────────────────────────
// productSchema
// ──────────────────────────────────────────────
describe("productSchema", () => {
  const validProduct = {
    name: "Coca Cola",
    category: "bebida_latas",
    sourceType: "compra",
    pricingMode: "fixed",
  };

  it("acepta producto válido mínimo", () => {
    expect(productSchema.validate(validProduct).error).toBeUndefined();
  });

  it("acepta producto válido completo", () => {
    const full = {
      ...validProduct,
      id: "550e8400-e29b-41d4-a716-446655440000",
      defaultPriceCents: 1000,
      barcode: "12345678",
      active: true,
    };
    expect(productSchema.validate(full).error).toBeUndefined();
  });

  it("acepta defaultPriceCents en null", () => {
    const { error } = productSchema.validate({ ...validProduct, defaultPriceCents: null });
    expect(error).toBeUndefined();
  });

  it("rechaza nombre vacío", () => {
    const { error } = productSchema.validate({ ...validProduct, name: "" });
    expect(error).toBeDefined();
  });

  it("rechaza nombre de 1 caracter (mín 2)", () => {
    const { error } = productSchema.validate({ ...validProduct, name: "A" });
    expect(error).toBeDefined();
  });

  it("rechaza nombre mayor a 200 caracteres", () => {
    const { error } = productSchema.validate({ ...validProduct, name: "A".repeat(201) });
    expect(error).toBeDefined();
  });

  it("rechaza categoría inválida", () => {
    const { error } = productSchema.validate({ ...validProduct, category: "categoria_falsa" });
    expect(error).toBeDefined();
  });

  it("acepta todas las categorías válidas", () => {
    for (const category of INVENTORY_PRODUCT_CATEGORIES) {
      const { error } = productSchema.validate({ ...validProduct, category });
      expect(error).toBeUndefined();
    }
  });

  it("rechaza sourceType inválido", () => {
    const { error } = productSchema.validate({ ...validProduct, sourceType: "regalo" });
    expect(error).toBeDefined();
  });

  it("rechaza pricingMode inválido", () => {
    const { error } = productSchema.validate({ ...validProduct, pricingMode: "dinamico" });
    expect(error).toBeDefined();
  });

  it("rechaza defaultPriceCents negativo", () => {
    const { error } = productSchema.validate({ ...validProduct, defaultPriceCents: -1 });
    expect(error).toBeDefined();
  });

  it("rechaza barcode menor a 6 caracteres", () => {
    const { error } = productSchema.validate({ ...validProduct, barcode: "123" });
    expect(error).toBeDefined();
  });

  it("rechaza uuid con formato inválido", () => {
    const { error } = productSchema.validate({ ...validProduct, id: "no-es-uuid" });
    expect(error).toBeDefined();
  });
});

// ──────────────────────────────────────────────
// scanSchema
// ──────────────────────────────────────────────
describe("scanSchema", () => {
  const validScan = {
    id: "550e8400-e29b-41d4-a716-446655440000",
    barcode: "12345678",
    scannedAt: new Date().toISOString(),
    deviceId: "DEVICE-001",
  };

  it("acepta scan válido mínimo", () => {
    expect(scanSchema.validate(validScan).error).toBeUndefined();
  });

  it("acepta scan con campos opcionales", () => {
    const { error } = scanSchema.validate({
      ...validScan,
      priceCents: 500,
      quantity: 3,
    });
    expect(error).toBeUndefined();
  });

  it("rechaza sin id", () => {
    const { id, ...rest } = validScan;
    expect(scanSchema.validate(rest).error).toBeDefined();
  });

  it("rechaza barcode menor a 6 caracteres", () => {
    const { error } = scanSchema.validate({ ...validScan, barcode: "123" });
    expect(error).toBeDefined();
  });

  it("rechaza scannedAt con formato incorrecto", () => {
    const { error } = scanSchema.validate({ ...validScan, scannedAt: "ayer" });
    expect(error).toBeDefined();
  });

  it("rechaza quantity 0 (mín 1)", () => {
    const { error } = scanSchema.validate({ ...validScan, quantity: 0 });
    expect(error).toBeDefined();
  });

  it("rechaza priceCents negativo", () => {
    const { error } = scanSchema.validate({ ...validScan, priceCents: -10 });
    expect(error).toBeDefined();
  });
});

// ──────────────────────────────────────────────
// bulkSchema
// ──────────────────────────────────────────────
describe("bulkSchema", () => {
  const validScan = {
    id: "550e8400-e29b-41d4-a716-446655440000",
    barcode: "12345678",
    scannedAt: new Date().toISOString(),
    deviceId: "DEVICE-001",
  };

  it("acepta bulk con un scan válido", () => {
    expect(bulkSchema.validate({ scans: [validScan] }).error).toBeUndefined();
  });

  it("acepta bulk con múltiples scans válidos", () => {
    expect(bulkSchema.validate({ scans: [validScan, validScan] }).error).toBeUndefined();
  });

  it("rechaza array vacío (mín 1 scan)", () => {
    expect(bulkSchema.validate({ scans: [] }).error).toBeDefined();
  });

  it("rechaza sin campo scans", () => {
    expect(bulkSchema.validate({}).error).toBeDefined();
  });

  it("rechaza si un scan del array es inválido", () => {
    const invalidScan = { ...validScan, barcode: "x" }; // barcode muy corto
    expect(bulkSchema.validate({ scans: [invalidScan] }).error).toBeDefined();
  });
});

// ──────────────────────────────────────────────
// variosSchema
// ──────────────────────────────────────────────
describe("variosSchema", () => {
  it("acepta payload válido mínimo", () => {
    expect(variosSchema.validate({ priceCents: 500 }).error).toBeUndefined();
  });

  it("acepta payload completo", () => {
    expect(
      variosSchema.validate({ priceCents: 1000, quantity: 2, deviceId: "CAJA-001" }).error
    ).toBeUndefined();
  });

  it("rechaza priceCents 0 (mín 1)", () => {
    expect(variosSchema.validate({ priceCents: 0 }).error).toBeDefined();
  });

  it("rechaza priceCents negativo", () => {
    expect(variosSchema.validate({ priceCents: -100 }).error).toBeDefined();
  });

  it("rechaza quantity 0 (mín 1)", () => {
    expect(variosSchema.validate({ priceCents: 500, quantity: 0 }).error).toBeDefined();
  });

  it("rechaza sin priceCents", () => {
    expect(variosSchema.validate({}).error).toBeDefined();
  });

  it("rechaza deviceId de 1 caracter (mín 2)", () => {
    expect(variosSchema.validate({ priceCents: 500, deviceId: "X" }).error).toBeDefined();
  });
});
