import Joi from "joi";

const allowedDomains = ["@alumnos.ubiobio.cl", "@ubiobio.cl"];

const domainEmailValidator = (value, helper) => {
  const isValidDomain = allowedDomains.some((domain) => value.toLowerCase().endsWith(domain));
  if (!isValidDomain) {
    return helper.message(
      El correo electrónico debe pertenecer a alguno de estos dominios: 
    );
  }
  return value;
};

export const authValidation = Joi.object({
  email: Joi.string()
    .min(10)
    .max(60)
    .email()
    .required()
    .messages({
      "string.empty": "El correo electrónico no puede estar vacío.",
      "any.required": "El correo electrónico es obligatorio.",
      "string.min": "El correo electrónico debe tener al menos 10 caracteres.",
      "string.max": "El correo electrónico debe tener como máximo 60 caracteres.",
    })
    .custom(domainEmailValidator, "Validación dominio email"),
  password: Joi.string()
    .min(8)
    .max(64)
    .required()
    .messages({
      "string.empty": "La contraseña no puede estar vacía.",
      "any.required": "La contraseña es obligatoria.",
      "string.min": "La contraseña debe tener al menos 8 caracteres.",
      "string.max": "La contraseña debe tener como máximo 64 caracteres.",
    }),
}).unknown(false).messages({
  "object.unknown": "No se permiten propiedades adicionales.",
});

export const registerValidation = Joi.object({
  fullName: Joi.string()
    .min(6)
    .max(100)
    .required()
    .messages({
      "string.empty": "El nombre completo no puede estar vacío.",
      "any.required": "El nombre completo es obligatorio.",
      "string.min": "El nombre completo debe tener al menos 6 caracteres.",
      "string.max": "El nombre completo debe tener como máximo 100 caracteres.",
    }),
  rut: Joi.string()
    .min(9)
    .max(12)
    .pattern(/^(?:(?:[1-9]\d{0}|[1-2]\d{1})(\.\d{3}){2}|[1-9]\d{6}|[1-2]\d{7}|29\.999\.999|29999999)-[\dkK]$/)
    .required()
    .messages({
      "string.empty": "El rut no puede estar vacío.",
      "any.required": "El rut es obligatorio.",
      "string.pattern.base": "Formato rut inválido, debe ser xx.xxx.xxx-x o xxxxxxxx-x.",
    }),
  email: Joi.string()
    .min(10)
    .max(60)
    .email()
    .required()
    .messages({
      "string.empty": "El correo electrónico no puede estar vacío.",
      "any.required": "El correo electrónico es obligatorio.",
      "string.min": "El correo electrónico debe tener al menos 10 caracteres.",
      "string.max": "El correo electrónico debe tener como máximo 60 caracteres.",
    })
    .custom(domainEmailValidator, "Validación dominio email"),
  role: Joi.string()
    .valid("directiva", "tesorera", "apoderado", "entrenador", "administrador")
    .required()
    .messages({
      "string.empty": "El rol no puede estar vacío.",
      "any.required": "El rol es obligatorio.",
      "any.only": "El rol proporcionado no es válido.",
    }),
  password: Joi.string()
    .min(8)
    .max(64)
    .required()
    .messages({
      "string.empty": "La contraseña no puede estar vacía.",
      "any.required": "La contraseña es obligatoria.",
      "string.min": "La contraseña debe tener al menos 8 caracteres.",
      "string.max": "La contraseña debe tener como máximo 64 caracteres.",
    }),
  phone: Joi.string()
    .allow(null, "")
    .max(20)
    .messages({
      "string.max": "El teléfono no puede superar los 20 caracteres.",
    }),
}).unknown(false).messages({
  "object.unknown": "No se permiten propiedades adicionales.",
});