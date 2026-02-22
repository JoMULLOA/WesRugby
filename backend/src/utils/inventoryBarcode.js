"use strict";
import crypto from "crypto";
import { INVENTORY_PRODUCT_CATEGORIES } from "../entity/inventoryProduct.entity.js";

const CATEGORY_PREFIXES = {
  bebida_latas: "BL",
  pasteleria: "PA",
  selladitos: "SE",
  cafeteria: "CF",
  pastillas: "PT",
  papas_fritas_cajita: "PF",
  bebidas_energeticas: "BE",
  varios: "VA",
};

function checksum(value) {
  const total = value
    .split("")
    .reduce((acc, char, index) => acc + char.charCodeAt(0) * (index + 1), 0);
  return String(total % 97).padStart(2, "0");
}

export function generateBarcodeCandidate(category) {
  if (!INVENTORY_PRODUCT_CATEGORIES.includes(category)) {
    throw new Error(`Unsupported inventory category: ${category}`);
  }
  const prefix = CATEGORY_PREFIXES[category] || "IN";
  const random = crypto.randomBytes(4).toString("hex").toUpperCase();
  const body = `${prefix}${random}`;
  return `${body}${checksum(body)}`;
}

export async function generateUniqueBarcode(repository, category) {
  const maxAttempts = 25;
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const candidate = generateBarcodeCandidate(category);
    const existing = await repository.findOne({
      where: { barcode: candidate },
    });
    if (!existing) {
      return candidate;
    }
  }
  throw new Error("Unable to generate unique barcode after multiple attempts");
}
