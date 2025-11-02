"use strict";
import { EntitySchema } from "typeorm";

const PRODUCT_CATEGORIES = [
  "bebida_latas",
  "pasteleria",
  "selladitos",
  "cafeteria",
  "pastillas",
  "papas_fritas_cajita",
  "bebidas_energeticas",
  "varios",
];

const SOURCE_TYPES = ["compra", "donacion"];
const PRICING_MODES = ["fixed", "variable"];

const InventoryProductSchema = new EntitySchema({
  name: "InventoryProduct",
  tableName: "inventory_products",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    name: {
      type: "varchar",
      length: 200,
      nullable: false,
    },
    category: {
      type: "enum",
      enum: PRODUCT_CATEGORIES,
      nullable: false,
    },
    sourceType: {
      type: "enum",
      enum: SOURCE_TYPES,
      nullable: false,
    },
    pricingMode: {
      type: "enum",
      enum: PRICING_MODES,
      nullable: false,
    },
    defaultPriceCents: {
      type: "int",
      nullable: true,
    },
    barcode: {
      type: "varchar",
      length: 40,
      nullable: false,
      unique: true,
    },
    active: {
      type: "boolean",
      default: true,
    },
    createdAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
    updatedAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      onUpdate: "CURRENT_TIMESTAMP",
      nullable: false,
    },
  },
  relations: {
    sales: {
      type: "one-to-many",
      target: "InventorySale",
      inverseSide: "product",
    },
  },
  indices: [
    {
      name: "IDX_INVENTORY_PRODUCT_CATEGORY",
      columns: ["category"],
    },
    {
      name: "IDX_INVENTORY_PRODUCT_BARCODE",
      columns: ["barcode"],
      unique: true,
    },
    {
      name: "IDX_INVENTORY_PRODUCT_ACTIVE",
      columns: ["active"],
    },
  ],
});

export const INVENTORY_PRODUCT_CATEGORIES = PRODUCT_CATEGORIES;
export const INVENTORY_SOURCE_TYPES = SOURCE_TYPES;
export const INVENTORY_PRICING_MODES = PRICING_MODES;
export default InventoryProductSchema;
