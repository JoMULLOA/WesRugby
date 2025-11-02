"use strict";
import { Router } from "express";
import {
  getHealth,
  getProducts,
  getManagementProducts,
  postProduct,
  deleteProduct,
  postReissueBarcode,
  getBarcodeSheet,
  getSalesSummary,
  postBulkScans,
  postVariosSale,
  getVariosProduct,
} from "../controllers/inventory.controller.js";

const router = Router();

router.get("/health", getHealth);
router.get("/products", getProducts);
router.get("/products/management", getManagementProducts);
router.post("/products", postProduct);
router.delete("/products/:id", deleteProduct);
router.post("/barcodes/reissue/:productId", postReissueBarcode);
router.get("/barcodes/sheet", getBarcodeSheet);
router.get("/sales/summary", getSalesSummary);
router.post("/scans/bulk", postBulkScans);
router.post("/sales/varios", postVariosSale);
router.get("/products/varios", getVariosProduct);

export default router;
