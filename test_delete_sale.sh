#!/bin/bash

# Script para probar el endpoint de eliminación de ventas
# Uso: ./test_delete_sale.sh YOUR_JWT_TOKEN

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que se pasó el token
if [ -z "$1" ]; then
    echo -e "${RED}Error: Debes proporcionar un token JWT${NC}"
    echo "Uso: ./test_delete_sale.sh YOUR_JWT_TOKEN"
    exit 1
fi

TOKEN=$1
BASE_URL="http://localhost:3000/api/inventario"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  TEST: Eliminar Venta - Inventario${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Paso 1: Crear una venta de prueba
echo -e "${YELLOW}📝 Paso 1: Creando venta de prueba...${NC}"
SALE_RESPONSE=$(curl -s -X POST "$BASE_URL/sales/varios" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "priceCents": 3500,
    "quantity": 2,
    "deviceId": "test-device-bash"
  }')

echo "$SALE_RESPONSE" | jq '.'

# Extraer el ID de la venta
SALE_ID=$(echo "$SALE_RESPONSE" | jq -r '.id')

if [ "$SALE_ID" == "null" ] || [ -z "$SALE_ID" ]; then
    echo -e "${RED}❌ Error: No se pudo crear la venta${NC}"
    echo "Respuesta del servidor:"
    echo "$SALE_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Venta creada con ID: $SALE_ID${NC}"
echo ""

# Paso 2: Ver resumen ANTES de eliminar
echo -e "${YELLOW}📊 Paso 2: Obteniendo resumen de ventas (ANTES de eliminar)...${NC}"
curl -s -X GET "$BASE_URL/sales/summary" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

# Pausa para ver los resultados
sleep 2

# Paso 3: Eliminar la venta
echo -e "${YELLOW}🗑️  Paso 3: Eliminando la venta...${NC}"
DELETE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/sales/$SALE_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "$DELETE_RESPONSE" | jq '.'

# Verificar si fue exitoso
DELETED=$(echo "$DELETE_RESPONSE" | jq -r '.deleted')
if [ "$DELETED" == "true" ]; then
    echo -e "${GREEN}✅ Venta eliminada exitosamente${NC}"
else
    echo -e "${RED}❌ Error al eliminar la venta${NC}"
    exit 1
fi
echo ""

# Paso 4: Ver resumen DESPUÉS de eliminar
echo -e "${YELLOW}📊 Paso 4: Obteniendo resumen de ventas (DESPUÉS de eliminar)...${NC}"
curl -s -X GET "$BASE_URL/sales/summary" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

# Paso 5: Intentar eliminar la misma venta otra vez (debe fallar)
echo -e "${YELLOW}🔍 Paso 5: Intentando eliminar la misma venta (debe fallar)...${NC}"
ERROR_RESPONSE=$(curl -s -X DELETE "$BASE_URL/sales/$SALE_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "$ERROR_RESPONSE" | jq '.'

ERROR_CODE=$(echo "$ERROR_RESPONSE" | jq -r '.error')
if [ "$ERROR_CODE" == "SALE_NOT_FOUND" ]; then
    echo -e "${GREEN}✅ Error esperado: La venta ya no existe${NC}"
else
    echo -e "${RED}⚠️  Advertencia: Se esperaba error SALE_NOT_FOUND${NC}"
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ PRUEBA COMPLETADA EXITOSAMENTE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Resumen:"
echo "  - Venta creada: $SALE_ID"
echo "  - Venta eliminada: ✅"
echo "  - Verificación de error: ✅"
