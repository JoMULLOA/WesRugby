# Comandos CURL para probar el Endpoint de Eliminación de Ventas

## Pre-requisitos
- El backend debe estar corriendo en `http://localhost:3000`
- Debes tener un token JWT válido (reemplaza `YOUR_TOKEN_HERE` con tu token real)

---

## 1️⃣ Paso 1: Crear una venta de prueba

### Opción A: Crear venta de "Varios" (precio variable)

```bash
curl -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "priceCents": 2500,
    "quantity": 2,
    "deviceId": "test-device"
  }'
```

**Respuesta esperada:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "productId": "...",
  "priceCents": 2500,
  "quantity": 2,
  "deviceId": "test-device",
  "scannedAt": "2025-11-10T...",
  "ingestId": null
}
```

📝 **Guarda el `id` de la respuesta**, lo necesitarás para eliminar la venta.

---

### Opción B: Crear venta con escaneo masivo

```bash
curl -X POST http://localhost:3000/api/inventario/scans/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "scans": [
      {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "barcode": "WR-BEB-001",
        "scannedAt": "2025-11-10T15:30:00Z",
        "deviceId": "test-device",
        "quantity": 1
      }
    ]
  }'
```

---

## 2️⃣ Paso 2: Verificar que la venta existe

### Obtener resumen de ventas

```bash
curl -X GET http://localhost:3000/api/inventario/sales/summary \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Respuesta esperada:**
```json
[
  {
    "productId": "...",
    "productName": "Varios",
    "category": "varios",
    "pricingMode": "variable",
    "barcode": "WR-VAR-001",
    "totalQuantity": 2,
    "totalAmountCents": 5000,
    "totalSales": 1,
    "lastSaleAt": "2025-11-10T..."
  }
]
```

---

## 3️⃣ Paso 3: Eliminar la venta

### Eliminar venta por ID

```bash
curl -X DELETE http://localhost:3000/api/inventario/sales/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

⚠️ **Reemplaza** `550e8400-e29b-41d4-a716-446655440000` con el ID real de tu venta.

**Respuesta exitosa:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "deleted": true,
  "productName": "Varios",
  "priceCents": 2500,
  "quantity": 2
}
```

**Error si no existe:**
```json
{
  "error": "SALE_NOT_FOUND",
  "message": "La venta no existe"
}
```

---

## 4️⃣ Paso 4: Verificar que fue eliminada

### Verificar el resumen nuevamente

```bash
curl -X GET http://localhost:3000/api/inventario/sales/summary \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Deberías ver que los totales han disminuido o que la venta ya no aparece si era la única.

---

## 🔧 Comandos Adicionales Útiles

### Listar todos los productos

```bash
curl -X GET http://localhost:3000/api/inventario/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Obtener producto "Varios"

```bash
curl -X GET http://localhost:3000/api/inventario/products/varios \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📋 Flujo Completo de Prueba (Copiar y Pegar)

### 1. Crear venta
```bash
SALE_RESPONSE=$(curl -s -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"priceCents": 3000, "quantity": 1, "deviceId": "test"}')

echo "Venta creada: $SALE_RESPONSE"
```

### 2. Extraer el ID de la venta (requiere jq)
```bash
SALE_ID=$(echo $SALE_RESPONSE | jq -r '.id')
echo "ID de la venta: $SALE_ID"
```

### 3. Ver resumen antes de eliminar
```bash
curl -X GET http://localhost:3000/api/inventario/sales/summary \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. Eliminar la venta
```bash
curl -X DELETE http://localhost:3000/api/inventario/sales/$SALE_ID \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 5. Verificar que fue eliminada
```bash
curl -X GET http://localhost:3000/api/inventario/sales/summary \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📝 Notas

- **Autenticación**: Todos los endpoints requieren un token JWT válido
- **UUID**: Los IDs de ventas son UUIDs versión 4
- **Cascada**: Al eliminar una venta, también se elimina el registro de `ingest` asociado si existe
- **Restricción**: No se puede eliminar un producto que tenga ventas asociadas (usa las ventas como historial)

---

## ❌ Posibles Errores

### 401 Unauthorized
```json
{
  "error": "No token provided"
}
```
**Solución**: Agrega el header `Authorization: Bearer YOUR_TOKEN`

### 404 Not Found
```json
{
  "error": "SALE_NOT_FOUND",
  "message": "La venta no existe"
}
```
**Solución**: Verifica que el ID sea correcto

### 400 Bad Request
```json
{
  "error": "SALE_ID_REQUIRED"
}
```
**Solución**: Verifica que el ID esté en la URL

---

## 🎯 Endpoint Implementado

- **Método**: `DELETE`
- **URL**: `/api/inventario/sales/:saleId`
- **Autenticación**: JWT (Bearer token)
- **Parámetros**: 
  - `saleId` (UUID) - ID de la venta a eliminar
- **Respuesta exitosa**: 200 OK
- **Respuesta error**: 404 Not Found, 400 Bad Request
