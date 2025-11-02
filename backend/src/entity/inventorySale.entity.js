"use strict";
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
    priceCents: {
      type: "int",
      nullable: false,
    },
    quantity: {
      type: "int",
      default: 1,
      nullable: false,
    },
    deviceId: {
      type: "varchar",
      length: 80,
      nullable: false,
    },
    scannedAt: {
      type: "timestamp with time zone",
      nullable: false,
    },
    createdAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
  },
  relations: {
    product: {
      type: "many-to-one",
      target: "InventoryProduct",
      joinColumn: {
        name: "product_id",
        referencedColumnName: "id",
      },
      nullable: false,
      onDelete: "RESTRICT",
    },
    ingest: {
      type: "one-to-one",
      target: "InventoryScanIngest",
      joinColumn: {
        name: "ingest_id",
        referencedColumnName: "id",
      },
      nullable: true,
      onDelete: "SET NULL",
      inverseSide: "sale",
    },
  },
  indices: [
    {
      name: "IDX_INVENTORY_SALE_PRODUCT",
      columns: ["product"],
    },
    {
      name: "IDX_INVENTORY_SALE_SCANNED_AT",
      columns: ["scannedAt"],
    },
  ],
});

export default InventorySaleSchema;
