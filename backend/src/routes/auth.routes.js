"use strict";
import { Router } from "express";
import { login, logout, register } from "../controllers/auth.controller.js";
import { sendCode, sendCoder, verifyCode } from "../controllers/verification.controller.js";
import { authenticateJwt } from "../middlewares/authentication.middleware.js";
import { isAdmin } from "../middlewares/authorization.middleware.js";

const router = Router();

router
  .post("/login", login)
  .post("/register", authenticateJwt, isAdmin, register) // Solo admins pueden crear usuarios
  .post("/logout", authenticateJwt, logout) // Requiere autenticación
  .post("/send-code", sendCode)
  .post("/send-coder", sendCoder)
  .post("/verify-code", verifyCode);

export default router;