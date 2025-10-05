import { EntitySchema } from "typeorm";

const InventorySaleSchema = new EntitySchema({
  name: "InventorySale",
  tableName: "inventory_sales",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    quantity: {
      type: "int",
      nullable: false,
    },
    totalAmount: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
    },
    soldAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
    buyerName: {
      type: "varchar",
      length: 150,
      nullable: true,
    },
    notes: {
      type: "text",
      nullable: true,
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
    { name: "IDX_INVENTORY_SALES_ITEM", columns: ["itemId"] },
    { name: "IDX_INVENTORY_SALES_SOLD_AT", columns: ["soldAt"] },
  ],
  relations: {
    item: {
      type: "many-to-one",
      target: "InventoryItem",
      joinColumn: { name: "itemId", referencedColumnName: "id" },
      nullable: false,
      onDelete: "CASCADE",
    },
    soldBy: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "soldById", referencedColumnName: "id" },
      nullable: false,
      onDelete: "RESTRICT",
    },
  },
});

export default InventorySaleSchema;