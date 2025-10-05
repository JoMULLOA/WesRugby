import jwt from "jsonwebtoken";
import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import { comparePassword, encryptPassword } from "../helpers/bcrypt.helper.js";
import { ACCESS_TOKEN_SECRET } from "../config/configEnv.js";

function ensureJwtSecret() {
  if (!ACCESS_TOKEN_SECRET) {
    throw new Error("ACCESS_TOKEN_SECRET is not defined");
  }
  return ACCESS_TOKEN_SECRET;
}

export async function loginService({ email, password }) {
  try {
    const userRepository = AppDataSource.getRepository(User);

    const userFound = await userRepository.findOne({ where: { email } });
    if (!userFound) {
      return [null, { dataInfo: "email", message: "El correo electrónico es incorrecto" }];
    }

    const isMatch = await comparePassword(password, userFound.password);
    if (!isMatch) {
      return [null, { dataInfo: "password", message: "La contraseña es incorrecta" }];
    }

    const payload = {
      id: userFound.id,
      nombreCompleto: userFound.nombreCompleto,
      email: userFound.email,
      rut: userFound.rut,
      rol: userFound.rol,
    };

    const token = jwt.sign(payload, ensureJwtSecret(), { expiresIn: "1d" });
    return [token, null];
  } catch (error) {
    console.error("Error al iniciar sesión:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function registerService(payload) {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const { nombreCompleto, email, rut, rol, password, carrera, fechaNacimiento, genero, telefono } = payload;

    const existingEmail = await userRepository.findOne({ where: { email } });
    if (existingEmail) {
      return [null, { field: "email", message: "Correo electrónico en uso" }];
    }

    const existingRut = await userRepository.findOne({ where: { rut } });
    if (existingRut) {
      return [null, { field: "rut", message: "Rut ya asociado a una cuenta" }];
    }

    const newUser = userRepository.create({
      nombreCompleto,
      email,
      rut,
      rol,
      password: await encryptPassword(password),
      carrera,
      fechaNacimiento,
      genero,
      telefono,
    });

    await userRepository.save(newUser);

    const { password: _password, ...safeUser } = newUser;
    return [safeUser, null];
  } catch (error) {
    console.error("Error al registrar un usuario:", error);
    return [null, "Error interno del servidor"];
  }
}