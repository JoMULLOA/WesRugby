"use strict";
import { EntitySchema } from "typeorm";

const InventoryScanIngestSchema = new EntitySchema({
  name: "InventoryScanIngest",
  tableName: "inventory_scan_ingests",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      nullable: false,
    },
    barcode: {
      type: "varchar",
      length: 40,
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
    sale: {
      type: "one-to-one",
      target: "InventorySale",
      inverseSide: "ingest",
    },
  },
  indices: [
    {
      name: "IDX_INVENTORY_SCAN_INGEST_BARCODE",
      columns: ["barcode"],
    },
    {
      name: "IDX_INVENTORY_SCAN_INGEST_DEVICE",
      columns: ["deviceId"],
    },
  ],
});

export default InventoryScanIngestSchema;
