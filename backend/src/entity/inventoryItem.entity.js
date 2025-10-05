import { EntitySchema } from "typeorm";

const InventoryItemSchema = new EntitySchema({
  name: "InventoryItem",
  tableName: "inventory_items",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    sku: {
      type: "varchar",
      length: 40,
      unique: true,
      nullable: false,
    },
    name: {
      type: "varchar",
      length: 120,
      nullable: false,
    },
    description: {
      type: "text",
      nullable: true,
    },
    stock: {
      type: "int",
      default: 0,
      nullable: false,
    },
    unitPrice: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
    },
    isActive: {
      type: "boolean",
      default: true,
      nullable: false,
    },
    createdAt: {
      type: "timestamp with time zone",
      createDate: true,
    },
    updatedAt: {
      type: "timestamp with time zone",
      updateDate: true,
    },
  },
  indices: [
    { name: "IDX_INVENTORY_ITEMS_SKU", columns: ["sku"], unique: true },
    { name: "IDX_INVENTORY_ITEMS_ACTIVE", columns: ["isActive"] },
  ],
  relations: {
    sales: {
      type: "one-to-many",
      target: "InventorySale",
      inverseSide: "item",
    },
  },
});

export default InventoryItemSchema;