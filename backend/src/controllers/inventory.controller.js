"use strict";
import Joi from "joi";
import {
  listActiveProducts,
  listAllProducts,
  upsertProduct,
  deleteProduct as deleteProductService,
  deleteProductPermanently as deleteProductPermanentlyService,
  reissueBarcode,
  generateSheetBuffer,
  listProductsByIds,
  listProductsByCategory,
  processBulkScans,
  createVariosSale,
  ensureVariosProduct,
  getSalesSummary as getSalesSummaryService,
  deleteSale as deleteSaleService,
} from "../services/inventory.service.js";
import { INVENTORY_PRICING_MODES, INVENTORY_PRODUCT_CATEGORIES, INVENTORY_SOURCE_TYPES } from "../entity/inventoryProduct.entity.js";

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

const sheetQuerySchema = Joi.object({
  category: Joi.string().valid(...INVENTORY_PRODUCT_CATEGORIES).optional(),
  ids: Joi.string().optional(),
  includeAll: Joi.boolean().optional().default(true),
  perPage: Joi.number().integer().min(1).optional(),
  cols: Joi.number().integer().min(1).max(6).optional(),
  rows: Joi.number().integer().min(1).max(20).optional(),
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

export async function getHealth(_req, res) {
  res.json({ ok: true });
}

export async function getProducts(_req, res, next) {
  try {
    const products = await listActiveProducts();
    res.json(products);
  } catch (error) {
    next(error);
  }
}

export async function getManagementProducts(req, res, next) {
  try {
    const includeInactive = req.query.includeInactive !== "false";
    const products = includeInactive ? await listAllProducts() : await listActiveProducts();
    res.json(products);
  } catch (error) {
    next(error);
  }
}

export async function postProduct(req, res, next) {
  try {
    const payload = await productSchema.validateAsync(req.body, { abortEarly: false });
    const product = await upsertProduct(payload);
    res.status(payload.id ? 200 : 201).json(product);
  } catch (error) {
    if (error.isJoi) {
      res.status(400).json({ error: "VALIDATION_ERROR", details: error.details });
      return;
    }
    if (error.message === "BARCODE_IN_USE") {
      res.status(409).json({ error: error.message });
      return;
    }
    if (error.message === "INVALID_CATEGORY" || error.message === "INVALID_SOURCE_TYPE" || error.message === "INVALID_PRICING_MODE") {
      res.status(400).json({ error: error.message });
      return;
    }
    if (error.message === "PRODUCT_NOT_FOUND") {
      res.status(404).json({ error: error.message });
      return;
    }
    next(error);
  }
}


export async function deleteProduct(req, res, next) {
  try {
    const { id } = req.params;
    if (!id) {
      return res.status(400).json({ error: "PRODUCT_ID_REQUIRED" });
    }
    const product = await deleteProductService(id);
    res.json(product);
  } catch (error) {
    if (error.message === "PRODUCT_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }
    next(error);
  }
}

export async function deleteProductPermanently(req, res, next) {
  try {
    const { id } = req.params;
    if (!id) {
      return res.status(400).json({ error: "PRODUCT_ID_REQUIRED" });
    }
    const result = await deleteProductPermanentlyService(id);
    res.json(result);
  } catch (error) {
    if (error.message === "PRODUCT_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }
    next(error);
  }
}

export async function postReissueBarcode(req, res, next) {
  try {
    const { productId } = req.params;
    if (!productId) {
      res.status(400).json({ error: "PRODUCT_ID_REQUIRED" });
      return;
    }
    const barcode = await reissueBarcode(productId);
    res.json({ productId, barcode });
  } catch (error) {
    if (error.message === "PRODUCT_NOT_FOUND") {
      res.status(404).json({ error: error.message });
      return;
    }
    next(error);
  }
}

export async function getBarcodeSheet(req, res, next) {
  try {
    const query = await sheetQuerySchema.validateAsync(req.query, { abortEarly: false, convert: true });
    let products = [];

    if (query.ids) {
      const ids = query.ids.split(",").map((value) => value.trim()).filter(Boolean);
      if (ids.length === 0) {
        res.status(400).json({ error: "INVALID_IDS" });
        return;
      }
      products = await listProductsByIds(ids);
    } else if (query.category) {
      products = await listProductsByCategory(query.category);
    } else if (query.includeAll) {
      products = await listActiveProducts();
    }

    if (products.length === 0) {
      res.status(404).json({ error: "NO_PRODUCTS_FOUND" });
      return;
    }

    const buffer = await generateSheetBuffer(products, {
      perPage: query.perPage,
      columns: query.cols,
      rows: query.rows,
    });

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", "inline; filename=inventory-barcodes.pdf");
    res.send(buffer);
  } catch (error) {
    if (error.isJoi) {
      res.status(400).json({ error: "VALIDATION_ERROR", details: error.details });
      return;
    }
    next(error);
  }
}


export async function getSalesSummary(req, res, next) {
  try {
    const { from, to, productId } = req.query;
    const filters = {};

    if (from) {
      const fromDate = new Date(from);
      if (!Number.isNaN(fromDate.getTime())) {
        filters.from = fromDate.toISOString();
      }
    }

    if (to) {
      const toDate = new Date(to);
      if (!Number.isNaN(toDate.getTime())) {
        filters.to = toDate.toISOString();
      }
    }

    if (productId) {
      filters.productId = productId;
    }

    const summary = await getSalesSummaryService(filters);
    res.json(summary);
  } catch (error) {
    next(error);
  }
}

export async function postBulkScans(req, res, next) {
  try {
    const payload = await bulkSchema.validateAsync(req.body, { abortEarly: false });
    const normalized = payload.scans.map((scan) => ({
      ...scan,
      scannedAt: new Date(scan.scannedAt),
    }));
    const result = await processBulkScans(normalized);
    
    // Si hay productos rechazados por precio variable, enviar error específico
    const variablePriceErrors = result.rejected.filter(
      r => r.reason === "MISSING_PRICE_FOR_VARIABLE"
    );
    
    if (variablePriceErrors.length > 0 && result.acceptedIds.length === 0) {
      return res.status(400).json({
        error: "VARIABLE_PRICE_REQUIRED",
        message: "Este producto requiere precio variable. Use el endpoint /api/inventario/sales/varios",
        rejected: result.rejected,
      });
    }
    
    res.json(result);
  } catch (error) {
    if (error.isJoi) {
      res.status(400).json({ error: "VALIDATION_ERROR", details: error.details });
      return;
    }
    next(error);
  }
}

export async function postVariosSale(req, res, next) {
  try {
    console.log('[DEBUG postVariosSale] req.body:', JSON.stringify(req.body));
    const payload = await variosSchema.validateAsync(req.body, { abortEarly: false });
    console.log('[DEBUG postVariosSale] payload after validation:', JSON.stringify(payload));
    const sale = await createVariosSale(payload);
    console.log('[DEBUG postVariosSale] sale result:', JSON.stringify(sale));
    res.status(201).json(sale);
  } catch (error) {
    if (error.isJoi) {
      res.status(400).json({ error: "VALIDATION_ERROR", details: error.details });
      return;
    }
    if (error.message === "PRICE_MUST_BE_POSITIVE") {
      res.status(400).json({ error: error.message });
      return;
    }
    next(error);
  }
}

export async function getVariosProduct(_req, res, next) {
  try {
    const product = await ensureVariosProduct();
    res.json(product);
  } catch (error) {
    next(error);
  }
}

export async function deleteSale(req, res, next) {
  try {
    const { saleId } = req.params;
    
    if (!saleId) {
      return res.status(400).json({ error: "SALE_ID_REQUIRED" });
    }
    
    const result = await deleteSaleService(saleId);
    res.json(result);
  } catch (error) {
    if (error.message === "SALE_NOT_FOUND") {
      return res.status(404).json({ error: "SALE_NOT_FOUND", message: "La venta no existe" });
    }
    next(error);
  }
}
