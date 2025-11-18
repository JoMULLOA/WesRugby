"use strict";
// Service for inventory management - products, sales and barcode generation
import { AppDataSource } from "../config/configDb.js";
import { In } from "typeorm";
import { INVENTORY_PRICING_MODES, INVENTORY_PRODUCT_CATEGORIES, INVENTORY_SOURCE_TYPES } from "../entity/inventoryProduct.entity.js";
import { generateUniqueBarcode } from "../utils/inventoryBarcode.js";
import { generateBarcodeSheet } from "../utils/inventoryPdf.js";

const PRODUCT_SEED = [
  { name: "Café / Milo", category: "comestibles", defaultPriceCents: 1000 },
  { name: "Té", category: "comestibles", defaultPriceCents: 1000 },
  { name: "Gatorade", category: "comestibles", defaultPriceCents: 2000 },
  { name: "Queque", category: "comestibles", defaultPriceCents: 1000 },
  { name: "Pie / Kuchen", category: "comestibles", defaultPriceCents: 2000 },
  { name: "Bebidas 350cc", category: "comestibles", defaultPriceCents: 1500 },
  { name: "Agua mineral", category: "comestibles", defaultPriceCents: 1500 },
  { name: "Papas fritas", category: "comestibles", defaultPriceCents: 1500 },
  { name: "Doritos", category: "comestibles", defaultPriceCents: 1500 },
  { name: "Selladitos", category: "comestibles", defaultPriceCents: 1500 },
  { name: "Hamburguesa", category: "comestibles", defaultPriceCents: 4000 },
  { name: "Bucales", category: "otros_productos", defaultPriceCents: 20000 },
  { name: "Tazones", category: "otros_productos", defaultPriceCents: 6000 },
  { name: "Bolsos", category: "otros_productos", defaultPriceCents: 3000 },
  { name: "Polerones", category: "otros_productos", defaultPriceCents: 27000 },
  { name: "Calcetas (S y M)", category: "otros_productos", defaultPriceCents: 5000 },
  { name: "Jockey Wessex", category: "otros_productos", defaultPriceCents: 5000 },
  { name: "Jockey Cóndores", category: "otros_productos", defaultPriceCents: 5000 },
  { name: "Canilleras XS", category: "otros_productos", defaultPriceCents: 6000 },
  { name: "Canilleras S", category: "otros_productos", defaultPriceCents: 6000 },
  { name: "Canilleras M", category: "otros_productos", defaultPriceCents: 6000 },
  { name: "Coderas M", category: "otros_productos", defaultPriceCents: 5000 },
  { name: "Llavero", category: "otros_productos", defaultPriceCents: 3000 },
  { name: "Pin Rugby", category: "otros_productos", defaultPriceCents: 3000 },
  { name: "Sticker", category: "otros_productos", defaultPriceCents: 2000 },
].map((item) => ({
  ...item,
  sourceType: "compra",
  pricingMode: "fixed",
}));

function productRepository() {
  return AppDataSource.getRepository("InventoryProduct");
}

function saleRepository() {
  return AppDataSource.getRepository("InventorySale");
}

function ingestRepository() {
  return AppDataSource.getRepository("InventoryScanIngest");
}

export async function listAllProducts() {
  const repo = productRepository();
  return repo.find({
    order: { category: "ASC", name: "ASC" },
  });
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

export async function deleteProduct(productId) {
  if (!productId) {
    throw new Error("PRODUCT_ID_REQUIRED");
  }
  const repo = productRepository();
  const existing = await repo.findOne({ where: { id: productId } });
  if (!existing) {
    throw new Error("PRODUCT_NOT_FOUND");
  }
  existing.active = false;
  return repo.save(existing);
}

export async function deleteProductPermanently(productId) {
  if (!productId) {
    throw new Error("PRODUCT_ID_REQUIRED");
  }
  return AppDataSource.transaction(async (manager) => {
    const repo = manager.getRepository("InventoryProduct");
    const saleRepo = manager.getRepository("InventorySale");
    const ingestRepo = manager.getRepository("InventoryScanIngest");

    const existing = await repo.findOne({ where: { id: productId } });
    if (!existing) {
      throw new Error("PRODUCT_NOT_FOUND");
    }

    const sales = await saleRepo.find({
      where: { product: { id: productId } },
      relations: { ingest: true },
    });

    if (sales.length) {
      for (const sale of sales) {
        if (sale.ingest) {
          await ingestRepo.remove(sale.ingest);
        }
      }
      await saleRepo.remove(sales);
    }

    await repo.remove(existing);
    return { deleted: true, productId, removedSales: sales.length };
  });
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
  const accepted = [];
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

      const { saleId } = await AppDataSource.transaction(async (manager) => {
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
          const savedSale = await saleRepo.save(sale);
          return { saleId: savedSale.id };
        }

        return { saleId: existingSale.id };
      });

      if (!saleId) {
        throw new Error("SALE_ID_NOT_AVAILABLE");
      }

      acceptedIds.push(scan.id);
      accepted.push({ scanId: scan.id, saleId });
    } catch (error) {
      rejected.push({ id: scan.id, reason: error.message || "UNKNOWN_ERROR" });
    }
  }

  return { acceptedIds, accepted, rejected };
}


export async function getSalesSummary(filters = {}) {
  const manager = AppDataSource.manager;
  const conditions = [];
  const params = [];

  if (filters.from) {
    params.push(filters.from);
    conditions.push(`sale."scannedAt" >= $${params.length}`);
  }
  if (filters.to) {
    params.push(filters.to);
    conditions.push(`sale."scannedAt" <= $${params.length}`);
  }
  if (filters.productId) {
    params.push(filters.productId);
    conditions.push(`sale.product_id = $${params.length}`);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const rows = await manager.query(
    `SELECT
       product.id AS "productId",
       product.name AS "productName",
       product.category AS "category",
       product."pricingMode" AS "pricingMode",
       product.barcode AS "barcode",
       COALESCE(SUM(sale.quantity), 0) AS "totalQuantity",
       COALESCE(SUM(sale."priceCents" * sale.quantity), 0) AS "totalAmountCents",
       COUNT(*) AS "totalSales",
       MAX(sale."scannedAt") AS "lastSaleAt"
     FROM inventory_sales sale
     INNER JOIN inventory_products product ON product.id = sale.product_id
     ${whereClause}
     GROUP BY product.id, product.name, product.category, product."pricingMode", product.barcode
     ORDER BY "totalAmountCents" DESC, "totalSales" DESC`,
    params,
  );

  return rows.map((row) => ({
    productId: row.productId,
    productName: row.productName,
    category: row.category,
    pricingMode: row.pricingMode,
    barcode: row.barcode,
    totalQuantity: Number.parseInt(row.totalQuantity, 10),
    totalAmountCents: Number.parseInt(row.totalAmountCents, 10),
    totalSales: Number.parseInt(row.totalSales, 10),
    lastSaleAt: row.lastSaleAt,
  }));
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

  const priceCentsToSave = Math.round(payload.priceCents);
  
  // Debug: Log del valor recibido y el que se va a guardar
  console.log('[DEBUG createVariosSale] payload.priceCents:', payload.priceCents);
  console.log('[DEBUG createVariosSale] priceCentsToSave:', priceCentsToSave);

  const sale = saleRepo.create({
    product: { id: varios.id },
    priceCents: priceCentsToSave,
    quantity,
    deviceId: payload.deviceId || "frontend-manual",
    scannedAt,
  });

  const saved = await saleRepo.save(sale);
  
  // Debug: Log del valor guardado
  console.log('[DEBUG createVariosSale] saved.priceCents:', saved.priceCents);

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

export async function deleteSale(saleId) {
  if (!saleId) {
    throw new Error("SALE_ID_REQUIRED");
  }
  
  const saleRepo = saleRepository();
  const ingestRepo = ingestRepository();
  
  const sale = await saleRepo.findOne({
    where: { id: saleId },
    relations: { ingest: true, product: true },
  });
  
  if (!sale) {
    throw new Error("SALE_NOT_FOUND");
  }
  
  // Si hay un ingest asociado, también eliminarlo
  if (sale.ingest) {
    await ingestRepo.remove(sale.ingest);
  }
  
  await saleRepo.remove(sale);
  
  return {
    id: saleId,
    deleted: true,
    productName: sale.product?.name || 'Unknown',
    priceCents: sale.priceCents,
    quantity: sale.quantity,
  };
}

export async function seedInventoryProducts() {
  const repo = productRepository();
  const allowedNames = new Set(PRODUCT_SEED.map((item) => item.name));
  const existing = await repo.find();

  // Desactivar productos que ya no forman parte del catálogo (excepto el registro "varios")
  for (const product of existing) {
    if (!allowedNames.has(product.name) && product.category !== "varios" && product.active) {
      product.active = false;
      await repo.save(product);
    }
  }

  for (const item of PRODUCT_SEED) {
    let product = await repo.findOne({ where: { name: item.name } });
    if (!product) {
      product = repo.create({ ...item });
    } else {
      product.sourceType = item.sourceType;
      product.category = item.category;
      product.pricingMode = item.pricingMode;
      product.defaultPriceCents = item.defaultPriceCents ?? null;
      product.active = true;
    }
    await ensureBarcode(product, repo);
    await repo.save(product);
  }

  await ensureVariosProduct();
}

