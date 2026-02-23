# 🧪 Guía de Tests del Proyecto WesRugby

## ¿Qué es un test y para qué sirve?

Un **test** es un trozo de código que verifica que otro trozo de código funciona correctamente.

La idea es simple:
1. Llamas a una función con datos conocidos
2. Afirmas que el resultado es el que esperas
3. Si no coincide → el test falla y sabes que algo está roto

**Ejemplo en lenguaje cotidiano:**
```
Dado: una contraseña "Hola1234"
Cuando: la cifro con bcrypt
Entonces: el resultado NO debe ser "Hola1234" (debe ser un hash irreconocible)
```

---

## ¿Qué tipos de tests hicimos?

Hicimos exclusivamente **tests unitarios**. Un test unitario prueba una sola función de forma aislada, sin base de datos, sin internet, sin nada externo.

```
Test Unitario  → Prueba UNA función de forma aislada     ← Hicimos esto ✅
Test Integración → Prueba varios módulos juntos
Test E2E       → Simula un usuario usando la app entera
```

---

## 📁 Estructura de archivos creados

```
WesRugby/
├── backend/
│   ├── vitest.config.js                          ← Configuración del framework de tests
│   └── tests/
│       ├── handlers/
│       │   └── responseHandlers.test.js          ← Tests de respuestas HTTP
│       ├── helpers/
│       │   └── bcrypt.helper.test.js             ← Tests de cifrado de contraseñas
│       ├── utils/
│       │   └── storage.utils.test.js             ← Tests de URLs de archivos
│       └── validations/
│           ├── auth.validation.test.js           ← Tests de validación de login/registro
│           └── inventory.schemas.test.js         ← Tests de validación de inventario
│
└── frontend/
    └── test/
        ├── widget_test.dart                      ← Reemplazado (era código de ejemplo)
        └── unit/
            ├── inventory_product_model_test.dart ← Tests del modelo de productos
            ├── user_model_test.dart              ← Tests del modelo de usuario
            ├── inventory_scan_payload_test.dart  ← Tests del payload de escaneo
            └── inventory_sales_summary_model_test.dart ← Tests del resumen de ventas
```

---

## 🔧 Herramientas que usamos

### Backend: **Vitest**
- Framework de tests para Node.js/JavaScript
- Instalado con: `npm install --save-dev vitest`
- Las funciones principales son:
  - `describe("grupo", () => {...})` → agrupa tests relacionados
  - `it("descripción", () => {...})` → define un test individual
  - `expect(valor).toBe(...)` → verifica que el valor es el esperado

### Frontend: **flutter_test**
- Ya viene incluido en Flutter, no hay que instalar nada
- Las funciones principales son:
  - `group("nombre", () {...})` → agrupa tests relacionados
  - `test("descripción", () {...})` → define un test individual
  - `expect(valor, matcher)` → verifica que el valor cumple la condición

---

## 📝 Explicación de cada archivo de test

---

### 1. `responseHandlers.test.js` — Respuestas HTTP

**¿Qué prueba?**
Las funciones que el backend usa para responder a las peticiones HTTP. Hay tres:
- `handleSuccess` → cuando todo salió bien (código 200, 201...)
- `handleErrorClient` → cuando el usuario mandó algo malo (código 400, 404...)
- `handleErrorServer` → cuando el servidor tuvo un fallo (código 500)

**¿Cómo funciona el test?**
Como estas funciones necesitan un objeto `res` (de Express), creamos uno **falso** (mock):

```js
function mockRes() {
  const res = {};
  res.status = vi.fn().mockReturnValue(res); // función falsa que graba lo que recibe
  res.json = vi.fn().mockReturnValue(res);   // función falsa que graba lo que recibe
  return res;
}
```

Luego llamamos a la función real con el mock y verificamos qué recibió:

```js
it("responde con statusCode y mensaje correcto", () => {
  const res = mockRes();
  handleSuccess(res, 200, "Operación exitosa");

  // ¿Se llamó res.status(200)?
  expect(res.status).toHaveBeenCalledWith(200);

  // ¿Se llamó res.json con el cuerpo correcto?
  expect(res.json).toHaveBeenCalledWith({
    success: true,
    message: "Operación exitosa",
  });
});
```

**Tests incluidos (11):**
- `handleSuccess` devuelve el statusCode correcto
- `handleSuccess` incluye `data` cuando se pasa
- `handleSuccess` NO incluye `data` cuando es null o undefined
- `handleErrorClient` devuelve `status: "Client error"` con detalles
- `handleErrorClient` usa `{}` como details por defecto
- `handleErrorClient` funciona con códigos 401 y 403
- `handleErrorServer` devuelve `status: "Server error"` con mensaje
- `handleErrorServer` no incluye campos extra

---

### 2. `bcrypt.helper.test.js` — Cifrado de contraseñas

**¿Qué prueba?**
Las funciones que cifran y verifican contraseñas. Las contraseñas NUNCA se guardan en texto plano en la base de datos, siempre se guarda un **hash** (una versión irreversible y cifrada).

**¿Cómo funciona?**
```js
it("genera un hash distinto a la contraseña original", async () => {
  const plain = "MiPassword123";
  const hash = await encryptPassword(plain);
  expect(hash).not.toBe(plain); // el hash NO es igual al original
});
```

**Tests incluidos (8):**
- El hash generado es diferente a la contraseña original
- El hash tiene formato bcrypt (empieza con `$2b$`)
- Dos llamadas con la misma clave generan hashes **distintos** (por el salt)
- El hash siempre tiene 60 caracteres
- `comparePassword` retorna `true` cuando la contraseña coincide con el hash
- `comparePassword` retorna `false` cuando NO coincide
- Es sensible a mayúsculas/minúsculas
- Retorna `false` con contraseña vacía

---

### 3. `storage.utils.test.js` — URLs de archivos

**¿Qué prueba?**
La función `resolveFileUrl` que convierte rutas de archivos locales en URLs completas.

**Ejemplo:**
```
"avatars/foto.jpg"  →  "http://localhost:3000/uploads/avatars/foto.jpg"
```

**Tests incluidos (11):**
- Retorna `null` si el valor es `null`, `undefined` o string vacío
- Si ya es una URL completa (`http://` o `https://`), la devuelve tal cual
- Construye la URL correcta para rutas relativas
- Si la ruta ya empieza con `uploads/`, no lo duplica
- Elimina barras `/` iniciales del path
- Usa protocolo HTTPS cuando el request lo indica
- Usa la variable de entorno `BACKEND_URL` si está definida

---

### 4. `auth.validation.test.js` — Validación de login y registro

**¿Qué prueba?**
Los esquemas Joi que validan los datos que manda el usuario al hacer login o registrarse. Joi es una librería que verifica que los datos tienen el formato correcto antes de procesarlos.

**Ejemplo:**
```js
it("rechaza email de dominio no permitido", () => {
  const { error } = authValidation.validate({
    email: "usuario@gmail.com",  // gmail no está permitido
    password: "Clave1234"
  });
  expect(error).toBeDefined(); // esperamos que HAYA error
});
```

**Tests del login (11):**
- Acepta credenciales válidas con dominios `@wessex.cl`, `@ubiobio.cl`, `@alumnos.ubiobio.cl`
- Rechaza emails de dominios no permitidos (gmail, hotmail, etc.)
- Rechaza email vacío o ausente
- Rechaza contraseña menor a 8 o mayor a 26 caracteres
- Rechaza contraseña ausente
- Rechaza propiedades extra no esperadas (`campoExtra: "algo"`)

**Tests del registro (11):**
- Acepta todos los roles válidos: `directiva`, `tesorera`, `apoderado`, `entrenador`
- Rechaza roles inválidos (`administrador`, `admin`, etc.)
- Rechaza nombre con números o menor a 10 caracteres
- Acepta RUT con o sin puntos (`12.345.678-9` y `12345678-9`)
- Rechaza RUT con formato incorrecto
- Rechaza contraseña con caracteres especiales (`!@#`)
- Rechaza propiedades extra

---

### 5. `inventory.schemas.test.js` — Validación del inventario

**¿Qué prueba?**
Los esquemas Joi del módulo de inventario y punto de venta. Hay 4 esquemas:

| Esquema | ¿Para qué se usa? |
|---|---|
| `productSchema` | Crear o editar un producto del inventario |
| `scanSchema` | Un escaneo de código de barras individual |
| `bulkSchema` | Un lote de varios escaneos a la vez |
| `variosSchema` | Venta de producto "varios" (sin código de barras) |

**Tests incluidos (32):**

`productSchema` (14 tests):
- Acepta producto válido mínimo y completo
- `defaultPriceCents` puede ser `null`
- Rechaza nombre vacío, de 1 caracter, o mayor a 200
- Rechaza categorías, sourceType y pricingMode inválidos
- Rechaza precio negativo y barcode menor a 6 caracteres
- Acepta las 10 categorías válidas

`scanSchema` (7 tests):
- Acepta scan mínimo y con campos opcionales
- Rechaza sin `id`, barcode corto, fecha con formato incorrecto
- Rechaza `quantity: 0` (mínimo es 1)
- Rechaza `priceCents` negativo

`bulkSchema` (5 tests):
- Acepta 1 o múltiples scans válidos
- Rechaza array vacío
- Rechaza si un scan del array es inválido

`variosSchema` (6 tests):
- Acepta con solo `priceCents`
- Rechaza `priceCents: 0` y negativos
- Rechaza `quantity: 0`
- Rechaza `deviceId` de 1 caracter

---

### 6. `inventory_product_model_test.dart` — Modelo de producto (Flutter)

**¿Qué prueba?**
La clase `InventoryProductModel` de Dart, que representa un producto del inventario en la app móvil/web.

**Tests incluidos (11):**
- `fromJson` parsea todos los campos correctamente desde un JSON del API
- `defaultPriceCents` puede ser `null`
- `active` es `true` por defecto si viene `null`
- `copyWith` crea una copia con campos modificados sin alterar el original
- `isVariable` retorna `true` solo cuando `pricingMode` es `"variable"`

---

### 7. `user_model_test.dart` — Modelo de usuario (Flutter)

**¿Qué prueba?**
La clase `User` que representa al usuario autenticado en la app.

**Tests incluidos (7):**
- Parsea todos los campos desde JSON
- Usa valores por defecto cuando los campos vienen `null` del API
- Convierte valores numéricos a string (para el RUT)
- Acepta los 4 roles válidos del sistema

---

### 8. `inventory_sales_summary_model_test.dart` — Resumen de ventas (Flutter)

**¿Qué prueba?**
La clase `InventorySalesSummaryModel`, que representa el resumen estadístico de ventas por producto.

**Tests incluidos (8):**
- Parsea todos los campos desde JSON
- Parsea totales que vienen como `String` desde PostgreSQL
- `lastSaleAt` puede ser `null`
- `totalAmount` convierte cents a double (`5000` → `5000.0`)

---

## 🚀 Cómo ejecutar los tests

### Backend
```bash
cd backend

# Ejecutar todos los tests (una sola vez)
npm test

# Ejecutar en modo watch (re-ejecuta al guardar un archivo)
npm run test:watch

# Con reporte de cobertura (qué % del código está cubierto)
npm run test:coverage
```

### Frontend
```bash
cd frontend

# Ejecutar todos los tests (una sola vez)
flutter test

# Ejecutar un archivo específico
flutter test test/unit/user_model_test.dart

# Con cobertura
flutter test --coverage
```

---

## 📊 Resultado actual

```
BACKEND   → 5 archivos, 84 tests, 0 errores ✅
FRONTEND  → 4 archivos, 32 tests, 0 errores ✅
TOTAL     → 116 tests pasando
```

---

## 💡 Conceptos clave para recordar

| Concepto | Significado |
|---|---|
| `expect(x).toBe(y)` | x debe ser exactamente igual a y |
| `expect(x).not.toBe(y)` | x NO debe ser igual a y |
| `expect(x).toBeDefined()` | x debe existir (no ser undefined) |
| `expect(x).toBeUndefined()` | x debe ser undefined |
| `expect(x).toBeNull()` | x debe ser null |
| `expect(x).toHaveLength(n)` | x debe tener longitud n |
| `vi.fn()` | Función falsa (mock) para espiar llamadas |
| `vi.mock(...)` | Reemplaza un módulo entero con una versión falsa |
| `describe/group` | Agrupa tests relacionados bajo un nombre |
| `it/test` | Define un test individual |
