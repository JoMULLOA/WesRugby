"use strict";
import { Router } from "express";
import {
  getHealth,
  getProducts,
  postProduct,
  postReissueBarcode,
  getBarcodeSheet,
  postBulkScans,
  postVariosSale,
  getVariosProduct,
} from "../controllers/inventory.controller.js";

const router = Router();

router.get("/health", getHealth);
router.get("/products", getProducts);
router.post("/products", postProduct);
router.post("/barcodes/reissue/:productId", postReissueBarcode);
router.get("/barcodes/sheet", getBarcodeSheet);
router.post("/scans/bulk", postBulkScans);
router.post("/sales/varios", postVariosSale);
router.get("/products/varios", getVariosProduct);

export default router;
