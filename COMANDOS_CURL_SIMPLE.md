# COMANDOS CURL - Prueba Rápida de Eliminación de Ventas

## ⚙️ CONFIGURACIÓN PREVIA

Primero, obtén un token JWT. Inicia sesión con:

```bash
# Login como directiva (ajusta email/password según tu BD)
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "directiva@example.com",
    "password": "tu_password"
  }'
```

Guarda el token que recibes en la respuesta.

---

## 🚀 COMANDOS PARA COPIAR Y PEGAR

### 1️⃣ CREAR VENTA

```bash
curl -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{"priceCents": 3500, "quantity": 2, "deviceId": "test-device"}'
```

**📋 Copia el `id` de la respuesta**

---

### 2️⃣ VER TODAS LAS VENTAS

```bash
curl -X GET http://localhost:3000/api/inventario/sales/summary \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

### 3️⃣ ELIMINAR VENTA

```bash
curl -X DELETE http://localhost:3000/api/inventario/sales/SALE_ID_AQUI \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**⚠️ Reemplaza `SALE_ID_AQUI` con el ID real**

---

### 4️⃣ VERIFICAR QUE FUE ELIMINADA

```bash
curl -X GET http://localhost:3000/api/inventario/sales/summary \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## 📝 EJEMPLO COMPLETO CON IDs REALES

```bash
# 1. Crear venta
curl -X POST http://localhost:3000/api/inventario/sales/varios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -d '{"priceCents": 5000, "quantity": 3, "deviceId": "terminal-1"}'

# Supongamos que retorna: {"id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", ...}

# 2. Eliminar la venta usando el ID
curl -X DELETE http://localhost:3000/api/inventario/sales/a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  -H "Authorization: Bearer TU_TOKEN_AQUI"

# Respuesta esperada: {"id": "a1b2c3d4-...", "deleted": true, "productName": "Varios", ...}
```

---

## 🔍 VERIFICACIÓN DE ERRORES

### Intentar eliminar venta que no existe:
```bash
curl -X DELETE http://localhost:3000/api/inventario/sales/00000000-0000-0000-0000-000000000000 \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

**Respuesta esperada:**
```json
{
  "error": "SALE_NOT_FOUND",
  "message": "La venta no existe"
}
```

---

## 💡 TIPS

1. **Obtener token**: Usa el endpoint `/api/auth/signin` con credenciales de directiva
2. **Reemplazar token**: Cambia `TU_TOKEN_AQUI` por tu token JWT real
3. **UUID válido**: Los IDs de ventas son UUIDs (ej: `550e8400-e29b-41d4-a716-446655440000`)
4. **Ver formato bonito**: Agrega `| jq` al final del comando si tienes `jq` instalado

---

## 🎯 ENDPOINT IMPLEMENTADO

```
DELETE /api/inventario/sales/:saleId
```

- **Autenticación**: Requerida (Bearer Token)
- **Parámetro**: `saleId` (UUID)
- **Respuesta 200**: `{id, deleted: true, productName, priceCents, quantity}`
- **Respuesta 404**: `{error: "SALE_NOT_FOUND", message: "La venta no existe"}`
- **Respuesta 400**: `{error: "SALE_ID_REQUIRED"}`
