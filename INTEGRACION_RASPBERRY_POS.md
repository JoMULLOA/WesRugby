# 🍓 Integración Sistema Raspberry POS con WesRugby API

## 📋 Configuración

### API Key
La API Key para el sistema Raspberry está configurada en el backend:

```
X-API-Key: raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction
```

⚠️ **IMPORTANTE**: Cambia esta clave en producción por una más segura.

---

## 🔌 Endpoints Disponibles para Raspberry

### 1️⃣ **Crear Venta (POST)**

```bash
curl -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -H "X-API-Key: raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction" \
  -d '{
    "priceCents": 3500,
    "quantity": 2,
    "deviceId": "raspberry-pos-001"
  }'
```

**Respuesta:**
```json
{
  "id": "uuid-de-la-venta",
  "productId": "...",
  "priceCents": 3500,
  "quantity": 2,
  "deviceId": "raspberry-pos-001",
  "scannedAt": "2025-11-11T...",
  "ingestId": null
}
```

---

### 2️⃣ **Eliminar Venta (DELETE)**

```bash
curl -X DELETE http://localhost:3000/api/inventario/sales/SALE_ID_AQUI \
  -H "X-API-Key: raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction"
```

**Respuesta exitosa:**
```json
{
  "id": "uuid-de-la-venta",
  "deleted": true,
  "productName": "Varios",
  "priceCents": 3500,
  "quantity": 2
}
```

**Respuesta error:**
```json
{
  "error": "SALE_NOT_FOUND",
  "message": "La venta no existe"
}
```

---

### 3️⃣ **Crear Ventas Masivas (Bulk POST)**

```bash
curl -X POST http://localhost:3000/api/inventario/scans/bulk \
  -H "Content-Type: application/json" \
  -H "X-API-Key: raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction" \
  -d '{
    "scans": [
      {
        "id": "uuid-generado-en-raspberry-1",
        "barcode": "WR-BEB-001",
        "scannedAt": "2025-11-11T12:00:00Z",
        "deviceId": "raspberry-pos-001",
        "quantity": 1
      },
      {
        "id": "uuid-generado-en-raspberry-2",
        "barcode": "WR-BEB-002",
        "scannedAt": "2025-11-11T12:01:00Z",
        "deviceId": "raspberry-pos-001",
        "quantity": 2
      }
    ]
  }'
```

---

## 💻 Código para Node.js (Sistema Raspberry)

### Configuración Axios

```javascript
// config/api.js
import axios from 'axios';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const API_KEY = process.env.API_KEY || 'raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY,
  },
  timeout: 10000, // 10 segundos
});
```

---

### Funciones para Gestionar Ventas

```javascript
// services/salesService.js
import { apiClient } from '../config/api.js';
import { v4 as uuidv4 } from 'uuid';

/**
 * Crear una venta de producto con precio variable
 */
export async function createSale(priceCents, quantity = 1) {
  try {
    const response = await apiClient.post('/inventario/sales/varios', {
      priceCents,
      quantity,
      deviceId: process.env.DEVICE_ID || 'raspberry-pos-001',
    });
    
    console.log('✅ Venta creada:', response.data);
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error creando venta:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
}

/**
 * Eliminar una venta por ID
 */
export async function deleteSale(saleId) {
  try {
    const response = await apiClient.delete(`/inventario/sales/${saleId}`);
    
    console.log('🗑️ Venta eliminada:', response.data);
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error eliminando venta:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
}

/**
 * Crear múltiples ventas (sincronización masiva)
 */
export async function syncSales(scans) {
  try {
    const response = await apiClient.post('/inventario/scans/bulk', {
      scans: scans.map(scan => ({
        id: scan.id || uuidv4(),
        barcode: scan.barcode,
        scannedAt: scan.scannedAt || new Date().toISOString(),
        deviceId: scan.deviceId || process.env.DEVICE_ID || 'raspberry-pos-001',
        quantity: scan.quantity || 1,
      })),
    });
    
    console.log('📦 Ventas sincronizadas:', response.data);
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error sincronizando ventas:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
}
```

---

### Ejemplo de Uso

```javascript
// main.js - Ejemplo de uso
import { createSale, deleteSale, syncSales } from './services/salesService.js';

// 1. Crear una venta
const result = await createSale(3500, 2);
if (result.success) {
  const saleId = result.data.id;
  console.log('ID de venta:', saleId);
  
  // 2. Eliminar la venta si es necesario
  const deleteResult = await deleteSale(saleId);
  console.log('Venta eliminada:', deleteResult.success);
}

// 3. Sincronizar ventas offline cuando hay internet
const offlineSales = [
  { barcode: 'WR-BEB-001', scannedAt: '2025-11-11T10:00:00Z', quantity: 1 },
  { barcode: 'WR-PAS-002', scannedAt: '2025-11-11T10:05:00Z', quantity: 2 },
];

const syncResult = await syncSales(offlineSales);
console.log('Sincronización:', syncResult.success);
```

---

## 🔒 Seguridad

### Variables de Entorno (.env) en Raspberry

```env
# API Configuration
API_BASE_URL=https://tu-servidor.com/api
API_KEY=raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction
DEVICE_ID=raspberry-pos-001

# Offline Database
OFFLINE_DB_PATH=./data/offline-sales.db

# Sync Configuration
SYNC_INTERVAL=300000
```

---

## 🔄 Flujo de Sincronización

### 1. **Sin Internet** (Modo Offline)
```javascript
// Guardar en BD local SQLite
await saveToLocalDB({
  barcode,
  priceCents,
  quantity,
  scannedAt: new Date().toISOString(),
  synced: false,
});
```

### 2. **Con Internet** (Sincronización)
```javascript
// Obtener ventas pendientes de sincronizar
const pendingSales = await getUnsyncedSales();

// Intentar sincronizar
const result = await syncSales(pendingSales);

if (result.success) {
  // Marcar como sincronizadas
  await markAsSynced(pendingSales.map(s => s.id));
}
```

### 3. **Eliminar Venta Errónea**
```javascript
// Si el usuario detecta un error y quiere eliminar
const saleId = 'uuid-de-venta-erronea';
const result = await deleteSale(saleId);

if (result.success) {
  // También eliminar de BD local
  await removeFromLocalDB(saleId);
}
```

---

## ✅ Ventajas de usar API Key

1. ✅ **No necesita login**: La Raspberry se conecta directamente
2. ✅ **Autenticación simple**: Solo un header `X-API-Key`
3. ✅ **Seguro**: La clave está en variable de entorno
4. ✅ **Rastreable**: El sistema identifica que es la Raspberry
5. ✅ **Funciona offline/online**: Compatible con tu flujo de sincronización

---

## 🧪 Pruebas

### Probar desde Raspberry

```bash
# 1. Crear venta
SALE_ID=$(curl -s -X POST http://tu-servidor.com/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -H "X-API-Key: raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction" \
  -d '{"priceCents": 1500, "quantity": 1, "deviceId": "raspberry-pos-001"}' \
  | jq -r '.id')

echo "Venta creada: $SALE_ID"

# 2. Eliminar venta
curl -X DELETE http://tu-servidor.com/api/inventario/sales/$SALE_ID \
  -H "X-API-Key: raspberry-pos-secure-key-2024-WesRugby-ChangeInProduction"
```

---

## 📝 Notas Importantes

- ⚠️ **Cambia la API Key en producción** por una generada con más entropía
- 🔐 **Usa HTTPS** en producción para cifrar la comunicación
- 📊 **Logs**: Todas las operaciones se registran con `deviceId: "raspberry-pos-001"`
- 🔄 **Idempotencia**: Usa UUIDs únicos para evitar ventas duplicadas
- 💾 **Respaldo**: Guarda localmente antes de sincronizar

---

## 🆘 Solución de Problemas

### Error: API_KEY_REQUIRED
```json
{
  "error": "API_KEY_REQUIRED",
  "message": "Se requiere una API Key válida en el header 'X-API-Key'"
}
```
**Solución**: Agrega el header `X-API-Key` con la clave correcta

### Error: INVALID_API_KEY
```json
{
  "error": "INVALID_API_KEY",
  "message": "API Key inválida"
}
```
**Solución**: Verifica que la API Key coincida con la del archivo `.env`

### Error: SALE_NOT_FOUND
```json
{
  "error": "SALE_NOT_FOUND",
  "message": "La venta no existe"
}
```
**Solución**: Verifica que el ID de la venta sea correcto y que aún exista en la BD
