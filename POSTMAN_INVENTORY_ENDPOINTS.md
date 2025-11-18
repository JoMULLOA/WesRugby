# Endpoints de Inventario - Guía Postman

## 📋 Información General

**Base URL**: `http://localhost:3000/api/inventario`

---

## 1️⃣ Escaneo Masivo (Productos con Precio Fijo)

### Endpoint
```
POST /api/inventario/scans/bulk
```

### Headers
```json
{
  "Content-Type": "application/json"
}
```

### Body (Productos con precio fijo - Coca Cola, Sprite, etc.)
```json
{
  "scans": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "barcode": "INV-COCA-350ML",
      "scannedAt": "2025-11-02T10:30:00.000Z",
      "deviceId": "scanner-001"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "barcode": "INV-SPRITE-350ML",
      "scannedAt": "2025-11-02T10:31:00.000Z",
      "deviceId": "scanner-001"
    }
  ]
}
```

### Respuesta Exitosa (200)
```json
{
  "acceptedIds": [
    "550e8400-e29b-41d4-a716-446655440001",
    "550e8400-e29b-41d4-a716-446655440002"
  ],
  "rejected": []
}
```

---

## 2️⃣ Venta de Producto "Varios" (Precio Variable)

### Endpoint
```
POST /api/inventario/sales/varios
```

### Headers
```json
{
  "Content-Type": "application/json"
}
```

### Body - Ejemplo 1: Venta simple
```json
{
  "priceCents": 1500,
  "quantity": 1,
  "deviceId": "scanner-001"
}
```

### Body - Ejemplo 2: Múltiples unidades
```json
{
  "priceCents": 800,
  "quantity": 3,
  "deviceId": "caja-principal"
}
```

### Body - Ejemplo 3: Con registro de ingest
```json
{
  "priceCents": 2000,
  "quantity": 2,
  "deviceId": "scanner-mobile",
  "recordIngest": "550e8400-e29b-41d4-a716-446655440099",
  "scannedAt": "2025-11-02T15:45:00.000Z"
}
```

### Respuesta Exitosa (201)
```json
{
  "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "productId": "a1b2c3d4-e5f6-4789-a012-3456789abcde",
  "priceCents": 1500,
  "quantity": 1,
  "deviceId": "scanner-001",
  "scannedAt": "2025-11-02T15:45:00.000Z",
  "ingestId": null
}
```

---

## 3️⃣ Intentar escanear "Varios" sin precio (ERROR esperado)

### Endpoint
```
POST /api/inventario/scans/bulk
```

### Body (Intentando escanear "Varios" sin priceCents)
```json
{
  "scans": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440099",
      "barcode": "INV-VARIOS",
      "scannedAt": "2025-11-02T16:00:00.000Z",
      "deviceId": "scanner-001"
    }
  ]
}
```

### Respuesta de Error (400)
```json
{
  "error": "VARIABLE_PRICE_REQUIRED",
  "message": "Este producto requiere precio variable. Use el endpoint /api/inventario/sales/varios",
  "rejected": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440099",
      "reason": "MISSING_PRICE_FOR_VARIABLE"
    }
  ]
}
```

---

## 4️⃣ Obtener Producto "Varios"

### Endpoint
```
GET /api/inventario/products/varios
```

### Respuesta (200)
```json
{
  "id": "a1b2c3d4-e5f6-4789-a012-3456789abcde",
  "name": "Varios",
  "category": "varios",
  "sourceType": "compra",
  "pricingMode": "variable",
  "defaultPriceCents": null,
  "barcode": "INV-VARIOS",
  "active": true,
  "createdAt": "2025-11-01T10:00:00.000Z",
  "updatedAt": "2025-11-01T10:00:00.000Z"
}
```

---

## 5️⃣ Resumen de Ventas

### Endpoint
```
GET /api/inventario/sales/summary
```

### Query Parameters (todos opcionales)
```
?from=2025-11-01T00:00:00.000Z
&to=2025-11-02T23:59:59.999Z
&productId=a1b2c3d4-e5f6-4789-a012-3456789abcde
```

### Respuesta (200)
```json
[
  {
    "productId": "a1b2c3d4-e5f6-4789-a012-3456789abcde",
    "productName": "Varios",
    "category": "varios",
    "barcode": "INV-VARIOS",
    "totalAmountCents": 4500,
    "totalQuantity": 3,
    "totalSales": 2,
    "lastSaleAt": "2025-11-02T15:45:00.000Z"
  },
  {
    "productId": "b2c3d4e5-f6a7-4890-b123-456789abcdef",
    "productName": "Coca Cola Lata 350ml",
    "category": "bebida_latas",
    "barcode": "INV-COCA-350ML",
    "totalAmountCents": 10800,
    "totalQuantity": 9,
    "totalSales": 9,
    "lastSaleAt": "2025-11-02T14:20:00.000Z"
  }
]
```

---

## 📝 Notas Importantes

### Diferencia entre productos fijos y variables:

1. **Productos con precio fijo** (Coca Cola, Sprite, etc.):
   - Usar: `POST /api/inventario/scans/bulk`
   - No requieren `priceCents` en el payload
   - El precio se toma de `defaultPriceCents` del producto

2. **Producto "Varios"** (precio variable):
   - Usar: `POST /api/inventario/sales/varios`
   - **REQUIERE** `priceCents` en el payload
   - El precio puede variar en cada venta
   - Si intentas usar `/scans/bulk` sin precio, obtendrás error 400

### Campos requeridos:

**POST /scans/bulk**:
- `id` (UUID v4)
- `barcode` (string)
- `scannedAt` (ISO date)
- `deviceId` (string)

**POST /sales/varios**:
- `priceCents` (integer > 0) **OBLIGATORIO**
- `quantity` (integer, default: 1)
- `deviceId` (string, default: "frontend-manual")
- `scannedAt` (ISO date, default: now)
- `recordIngest` (UUID, opcional)

### Conversión de precios:

- El backend trabaja en **centavos** (priceCents)
- Ejemplo: $1.500 CLP = 1500 centavos
- Ejemplo: $800 CLP = 800 centavos

---

## 🧪 Ejemplos de Prueba Rápida

### Prueba 1: Vender producto fijo
```bash
curl -X POST http://localhost:3000/api/inventario/scans/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "scans": [{
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "barcode": "INV-COCA-350ML",
      "scannedAt": "2025-11-02T10:30:00.000Z",
      "deviceId": "test"
    }]
  }'
```

**Respuesta 200 OK (productos fijos o mezclados):**
```json
{
  "acceptedIds": [
    "550e8400-e29b-41d4-a716-446655440001"
  ],
  "accepted": [
    {
      "scanId": "550e8400-e29b-41d4-a716-446655440001",
      "saleId": "4c332d14-9f4f-4f1f-91df-93b28e7314c7"
    }
  ],
  "rejected": []
}
```

> `acceptedIds` se mantiene para compatibilidad, pero ahora `accepted[]` incluye el `saleId` generado en el backend para que puedas eliminar la venta con `DELETE /api/inventario/sales/{saleId}`.

### Prueba 2: Vender "Varios" con precio
```bash
curl -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -d '{
    "priceCents": 1500,
    "quantity": 1,
    "deviceId": "test"
  }'
```

### Prueba 3: Error al escanear "Varios" sin precio
```bash
curl -X POST http://localhost:3000/api/inventario/scans/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "scans": [{
      "id": "550e8400-e29b-41d4-a716-446655440099",
      "barcode": "INV-VARIOS",
      "scannedAt": "2025-11-02T16:00:00.000Z",
      "deviceId": "test"
    }]
  }'
```

