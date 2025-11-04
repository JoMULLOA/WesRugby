# 🔄 Flujo de Ventas - Inventario WesRugby

## 📊 Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────┐
│                   ESCANEO DE PRODUCTO                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                   ┌──────────────────┐
                   │ ¿Qué producto?   │
                   └──────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐            ┌──────────────────┐
    │ Precio FIJO     │            │ Precio VARIABLE  │
    │ (Coca, Sprite)  │            │ (Varios)         │
    └─────────────────┘            └──────────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐            ┌──────────────────┐
    │ POST /scans/    │            │ POST /sales/     │
    │      bulk       │            │      varios      │
    └─────────────────┘            └──────────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐            ┌──────────────────┐
    │ NO requiere     │            │ SÍ requiere      │
    │ priceCents      │            │ priceCents       │
    └─────────────────┘            └──────────────────┘
              │                               │
              └───────────────┬───────────────┘
                              ▼
                    ┌──────────────────┐
                    │ Venta registrada │
                    │ en BD            │
                    └──────────────────┘
```

---

## 🎯 Casos de Uso

### ✅ CASO 1: Venta de Coca Cola (Precio Fijo)

**Paso 1**: Escanear código de barras
```
Barcode: INV-COCA-350ML
```

**Paso 2**: Enviar a `/scans/bulk`
```json
POST /api/inventario/scans/bulk
{
  "scans": [{
    "id": "uuid-generado",
    "barcode": "INV-COCA-350ML",
    "scannedAt": "2025-11-02T10:30:00.000Z",
    "deviceId": "scanner-001"
  }]
}
```

**Resultado**: ✅ Venta registrada con precio de $1200 (defaultPriceCents)

---

### ✅ CASO 2: Venta de "Varios" (Precio Variable)

**Paso 1**: Detectar que es producto "Varios"
```
Barcode: INV-VARIOS
Category: varios
PricingMode: variable
```

**Paso 2**: Solicitar precio al usuario
```
UI: "Ingrese el precio del producto"
Usuario ingresa: $1500
```

**Paso 3**: Enviar a `/sales/varios`
```json
POST /api/inventario/sales/varios
{
  "priceCents": 1500,
  "quantity": 1,
  "deviceId": "scanner-001"
}
```

**Resultado**: ✅ Venta registrada con precio de $1500

---

### ❌ CASO 3: Error - Varios sin precio

**Paso 1**: Intentar escanear "Varios" como producto normal
```json
POST /api/inventario/scans/bulk
{
  "scans": [{
    "id": "uuid-generado",
    "barcode": "INV-VARIOS",
    "scannedAt": "2025-11-02T10:30:00.000Z",
    "deviceId": "scanner-001"
    // ❌ Falta priceCents
  }]
}
```

**Resultado**: ❌ Error 400
```json
{
  "error": "VARIABLE_PRICE_REQUIRED",
  "message": "Este producto requiere precio variable. Use el endpoint /api/inventario/sales/varios",
  "rejected": [{
    "id": "uuid-generado",
    "reason": "MISSING_PRICE_FOR_VARIABLE"
  }]
}
```

---

## 🔍 Identificación de Productos

### Base de Datos - Tabla `inventory_products`

| id | name | barcode | pricingMode | defaultPriceCents |
|----|------|---------|-------------|-------------------|
| 001 | Coca Cola | INV-COCA-350ML | **fixed** | 1200 |
| 002 | Sprite | INV-SPRITE-350ML | **fixed** | 1200 |
| 003 | Varios | INV-VARIOS | **variable** | null |

---

## 🛠️ Implementación en el Frontend

### Paso 1: Detectar tipo de producto
```javascript
// Al escanear código de barras
const product = await fetchProductByBarcode(barcode);

if (product.pricingMode === 'variable') {
  // Producto "Varios" - pedir precio
  showPriceInputDialog();
} else {
  // Producto con precio fijo - procesar directamente
  sendBulkScan(product);
}
```

### Paso 2: Función para "Varios"
```javascript
async function handleVariosProduct(barcode) {
  const price = await showPriceDialog(); // UI modal/dialog
  
  if (!price || price <= 0) {
    showError('Precio inválido');
    return;
  }
  
  const response = await fetch('/api/inventario/sales/varios', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      priceCents: Math.round(price * 100), // Convertir pesos a centavos
      quantity: 1,
      deviceId: 'app-mobile'
    })
  });
  
  if (response.ok) {
    showSuccess('Venta registrada');
  }
}
```

### Paso 3: Función para productos fijos
```javascript
async function handleFixedPriceProduct(barcode) {
  const scanId = generateUUID();
  
  const response = await fetch('/api/inventario/scans/bulk', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      scans: [{
        id: scanId,
        barcode: barcode,
        scannedAt: new Date().toISOString(),
        deviceId: 'app-mobile'
      }]
    })
  });
  
  const result = await response.json();
  
  if (result.acceptedIds.includes(scanId)) {
    showSuccess('Venta registrada');
  } else {
    showError(result.rejected[0].reason);
  }
}
```

---

## 📝 Checklist de Implementación

- [ ] **Backend**: ✅ Ya implementado
  - [x] Endpoint `/scans/bulk` valida productos
  - [x] Endpoint `/sales/varios` acepta precio variable
  - [x] Retorna error 400 si "Varios" sin precio

- [ ] **Frontend**: Pendiente
  - [ ] Detectar `pricingMode` del producto
  - [ ] Mostrar dialog de precio para "Varios"
  - [ ] Routing condicional según tipo de producto
  - [ ] Validación de precio mínimo ($1 = 1 centavo)

---

## 🧪 Testing Rápido

### Test 1: Producto normal funciona
```bash
curl -X POST http://localhost:3000/api/inventario/scans/bulk \
  -H "Content-Type: application/json" \
  -d '{"scans":[{"id":"test-001","barcode":"INV-COCA-350ML","scannedAt":"2025-11-02T10:00:00Z","deviceId":"test"}]}'
```
**Esperado**: Status 200, acceptedIds contiene "test-001"

### Test 2: Varios con precio funciona
```bash
curl -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -d '{"priceCents":1500,"quantity":1,"deviceId":"test"}'
```
**Esperado**: Status 201, retorna venta creada

### Test 3: Varios sin precio falla
```bash
curl -X POST http://localhost:3000/api/inventario/scans/bulk \
  -H "Content-Type: application/json" \
  -d '{"scans":[{"id":"test-002","barcode":"INV-VARIOS","scannedAt":"2025-11-02T10:00:00Z","deviceId":"test"}]}'
```
**Esperado**: Status 400, error "VARIABLE_PRICE_REQUIRED"

---

## 📞 Resumen Ejecutivo

### Endpoint para productos con precio fijo:
```
POST /api/inventario/scans/bulk
```
- **Usa para**: Coca Cola, Sprite, Fanta, etc.
- **NO envíes**: priceCents (se toma de la BD)

### Endpoint para producto "Varios":
```
POST /api/inventario/sales/varios
```
- **Usa para**: Solo producto "Varios" (INV-VARIOS)
- **SÍ envía**: priceCents (obligatorio)
- **Ejemplo**: `{"priceCents": 1500, "quantity": 1, "deviceId": "scanner"}`

