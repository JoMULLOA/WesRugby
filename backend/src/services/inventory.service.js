"use strict";
import { AppDataSource } from "../config/configDb.js";
import { In } from "typeorm";
import { INVENTORY_PRICING_MODES, INVENTORY_PRODUCT_CATEGORIES, INVENTORY_SOURCE_TYPES } from "../entity/inventoryProduct.entity.js";
import { generateUniqueBarcode } from "../utils/inventoryBarcode.js";
import { generateBarcodeSheet } from "../utils/inventoryPdf.js";

const PRODUCT_SEED = [
  {
    name: "Coca Cola Lata 350ml",
    category: "bebida_latas",
    sourceType: "compra",
    pricingMode: "fixed",
    defaultPriceCents: 1200,
  },
  {
    name: "Kuchen Casero",
    category: "pasteleria",
    sourceType: "donacion",
    pricingMode: "fixed",
    defaultPriceCents: 1500,
  },
  {
    name: "Selladito Jamon Queso",
    category: "selladitos",
    sourceType: "donacion",
    pricingMode: "fixed",
    defaultPriceCents: 800,
  },
  {
    name: "Cafe Americano",
    category: "cafeteria",
    sourceType: "donacion",
    pricingMode: "fixed",
    defaultPriceCents: 500,
  },
  {
    name: "Mentitas Clasicas",
    category: "pastillas",
    sourceType: "compra",
    pricingMode: "fixed",
    defaultPriceCents: 300,
  },
  {
    name: "Papas Fritas Cajita Original",
    category: "papas_fritas_cajita",
    sourceType: "compra",
    pricingMode: "fixed",
    defaultPriceCents: 900,
  },
  {
    name: "Bebida Energetica Xtreme",
    category: "bebidas_energeticas",
    sourceType: "compra",
    pricingMode: "fixed",
    defaultPriceCents: 1800,
  },
  {
    name: "Varios",
    category: "varios",
    sourceType: "compra",
    pricingMode: "variable",
    defaultPriceCents: null,
  },
];

function productRepository() {
  return AppDataSource.getRepository("InventoryProduct");
}

function saleRepository() {
  return AppDataSource.getRepository("InventorySale");
}

function ingestRepository() {
  return AppDataSource.getRepository("InventoryScanIngest");
}

export async function listActiveProducts() {
  const repo = productRepository();
  return repo.find({
    where: { active: true },
    order: { category: "ASC", name: "ASC" },
  });
}

export async function listProductsByIds(ids) {
  if (!Array.isArray(ids) || ids.length === 0) {
    return [];
  }
  const repo = productRepository();
  return repo.find({
    where: { id: In(ids), active: true },
  });
}

export async function listProductsByCategory(category) {
  const repo = productRepository();
  return repo.find({
    where: { category, active: true },
    order: { name: "ASC" },
  });
}

async function ensureBarcode(product, repo) {
  if (product.barcode) {
    return product.barcode;
  }
  const unique = await generateUniqueBarcode(repo, product.category);
  product.barcode = unique;
  return unique;
}

function normalizePayload(payload) {
  const normalized = { ...payload };
  if (normalized.category === "varios") {
    normalized.pricingMode = "variable";
    normalized.defaultPriceCents = null;
  }
  if (normalized.pricingMode === "variable") {
    normalized.defaultPriceCents = null;
  }
  return normalized;
}

export async function upsertProduct(payload) {
  const repo = productRepository();
  const data = normalizePayload(payload);

  if (!INVENTORY_PRODUCT_CATEGORIES.includes(data.category)) {
    throw new Error("INVALID_CATEGORY");
  }
  if (!INVENTORY_SOURCE_TYPES.includes(data.sourceType)) {
    throw new Error("INVALID_SOURCE_TYPE");
  }
  if (!INVENTORY_PRICING_MODES.includes(data.pricingMode)) {
    throw new Error("INVALID_PRICING_MODE");
  }

  if (!data.id) {
    const entity = repo.create({
      name: data.name,
      category: data.category,
      sourceType: data.sourceType,
      pricingMode: data.pricingMode,
      defaultPriceCents: data.defaultPriceCents ?? null,
      barcode: data.barcode || (await generateUniqueBarcode(repo, data.category)),
      active: data.active !== undefined ? data.active : true,
    });
    return repo.save(entity);
  }

  const existing = await repo.findOne({ where: { id: data.id } });
  if (!existing) {
    throw new Error("PRODUCT_NOT_FOUND");
  }

  if (data.barcode && data.barcode !== existing.barcode) {
    const collision = await repo.findOne({ where: { barcode: data.barcode } });
    if (collision && collision.id !== data.id) {
      throw new Error("BARCODE_IN_USE");
    }
    existing.barcode = data.barcode;
  } else {
    await ensureBarcode(existing, repo);
  }

  existing.name = data.name;
  existing.category = data.category;
  existing.sourceType = data.sourceType;
  existing.pricingMode = data.pricingMode;
  existing.defaultPriceCents = data.defaultPriceCents ?? null;
  existing.active = data.active !== undefined ? data.active : existing.active;

  return repo.save(existing);
}

export async function reissueBarcode(productId) {
  const repo = productRepository();
  const product = await repo.findOne({ where: { id: productId } });
  if (!product) {
    throw new Error("PRODUCT_NOT_FOUND");
  }
  product.barcode = await generateUniqueBarcode(repo, product.category);
  await repo.save(product);
  return product.barcode;
}

export async function ensureVariosProduct() {
  const repo = productRepository();
  let varios = await repo.findOne({ where: { category: "varios" } });
  if (!varios) {
    varios = repo.create({
      name: "Varios",
      category: "varios",
      sourceType: "compra",
      pricingMode: "variable",
      defaultPriceCents: null,
      barcode: await generateUniqueBarcode(repo, "varios"),
      active: true,
    });
    await repo.save(varios);
  } else {
    if (varios.pricingMode !== "variable" || varios.defaultPriceCents !== null) {
      varios.pricingMode = "variable";
      varios.defaultPriceCents = null;
      await repo.save(varios);
    }
    await ensureBarcode(varios, repo);
  }
  return varios;
}

export async function generateSheetBuffer(products, options) {
  const labels = products.map((product) => ({
    name: product.name,
    barcode: product.barcode,
    category: product.category,
  }));
  return generateBarcodeSheet(labels, options);
}

function resolvePrice(product, scan) {
  if (product.pricingMode === "variable") {
    if (typeof scan.priceCents !== "number") {
      throw new Error("MISSING_PRICE_FOR_VARIABLE");
    }
    if (scan.priceCents <= 0) {
      throw new Error("INVALID_PRICE");
    }
    return Math.round(scan.priceCents);
  }
  if (product.defaultPriceCents === null || product.defaultPriceCents === undefined) {
    throw new Error("MISSING_DEFAULT_PRICE");
  }
  return product.defaultPriceCents;
}

export async function processBulkScans(scans) {
  const repo = productRepository();
  const acceptedIds = [];
  const rejected = [];

  for (const scan of scans) {
    try {
      const product = await repo.findOne({ where: { barcode: scan.barcode, active: true } });
      if (!product) {
        rejected.push({ id: scan.id, reason: "BARCODE_NOT_MAPPED" });
        continue;
      }

      let priceCents;
      try {
        priceCents = resolvePrice(product, scan);
      } catch (priceError) {
        rejected.push({ id: scan.id, reason: priceError.message });
        continue;
      }

      const quantity = Number.isInteger(scan.quantity) && scan.quantity > 0 ? scan.quantity : 1;
      const scannedAt = scan.scannedAt instanceof Date ? scan.scannedAt : new Date(scan.scannedAt);

      await AppDataSource.transaction(async (manager) => {
        const ingestRepo = manager.getRepository("InventoryScanIngest");
        const saleRepo = manager.getRepository("InventorySale");

        let ingest = await ingestRepo.findOne({ where: { id: scan.id } });
        if (!ingest) {
          ingest = ingestRepo.create({
            id: scan.id,
            barcode: scan.barcode,
            deviceId: scan.deviceId,
            scannedAt,
          });
          await ingestRepo.save(ingest);
        }

        const existingSale = await saleRepo.findOne({ where: { ingest: { id: ingest.id } }, relations: { ingest: true } });
        if (!existingSale) {
          const sale = saleRepo.create({
            product: { id: product.id },
            priceCents,
            quantity,
            deviceId: scan.deviceId,
            scannedAt,
            ingest,
          });
          await saleRepo.save(sale);
        }
      });

      acceptedIds.push(scan.id);
    } catch (error) {
      rejected.push({ id: scan.id, reason: error.message || "UNKNOWN_ERROR" });
    }
  }

  return { acceptedIds, rejected };
}

export async function createVariosSale(payload) {
  if (!payload || typeof payload.priceCents !== "number" || payload.priceCents <= 0) {
    throw new Error("PRICE_MUST_BE_POSITIVE");
  }
  const varios = await ensureVariosProduct();
  const saleRepo = saleRepository();
  const ingestRepo = ingestRepository();
  const scannedAt = payload.scannedAt ? new Date(payload.scannedAt) : new Date();
  const quantity = Number.isInteger(payload.quantity) && payload.quantity > 0 ? payload.quantity : 1;

  const sale = saleRepo.create({
    product: { id: varios.id },
    priceCents: Math.round(payload.priceCents),
    quantity,
    deviceId: payload.deviceId || "frontend-manual",
    scannedAt,
  });

  const saved = await saleRepo.save(sale);

  let ingestId = null;
  if (payload.recordIngest) {
    const ingest = ingestRepo.create({
      id: payload.recordIngest,
      barcode: varios.barcode,
      deviceId: payload.deviceId || "frontend-manual",
      scannedAt,
    });
    await ingestRepo.save(ingest);
    ingestId = ingest.id;
    await saleRepo.update({ id: saved.id }, { ingest: { id: ingest.id } });
  }

  return {
    id: saved.id,
    productId: varios.id,
    priceCents: saved.priceCents,
    quantity: saved.quantity,
    deviceId: saved.deviceId,
    scannedAt: saved.scannedAt,
    ingestId,
  };
}

export async function seedInventoryProducts() {
  const repo = productRepository();
  for (const item of PRODUCT_SEED) {
    let product = await repo.findOne({ where: { name: item.name } });
    if (!product) {
      product = repo.create({ ...item });
    } else {
      product.sourceType = item.sourceType;
      product.category = item.category;
      product.pricingMode = item.pricingMode;
      product.defaultPriceCents = item.defaultPriceCents;
      product.active = true;
    }
    await ensureBarcode(product, repo);
    await repo.save(product);
  }
}

