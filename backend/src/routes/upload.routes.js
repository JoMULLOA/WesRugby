"use strict";
import { Router } from "express";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isDirectiva } from "../middlewares/authorization.middleware.js";
import { uploadPublicMedia } from "../middlewares/upload.middleware.js";
import {
  uploadImagen,
  getImagen,
  deleteImagen,
} from "../controllers/upload.controller.js";

const router = Router();

router.post(
  "/imagen",
  authenticateJwt,
  isDirectiva,
  uploadPublicMedia.single("image"),
  uploadImagen,
);

router.get("/imagen/:key", getImagen);

router.delete("/imagen/:key", authenticateJwt, isDirectiva, deleteImagen);

export default router;
