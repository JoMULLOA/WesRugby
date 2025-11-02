"use strict";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import { AppDataSource, connectDB } from "../config/configDb.js";
import { listActiveProducts, listProductsByCategory, listProductsByIds, generateSheetBuffer, seedInventoryProducts } from "../services/inventory.service.js";

function parseArgs(argv) {
  const args = { includeAll: true };
  for (const item of argv) {
    if (!item.startsWith("--")) {
      continue;
    }
    const [key, value] = item.substring(2).split("=");
    switch (key) {
      case "category":
        if (value) {
          args.category = value;
        }
        break;
      case "ids":
        if (value) {
          args.ids = value.split(",").map((id) => id.trim()).filter(Boolean);
        }
        break;
      case "includeAll":
        args.includeAll = value !== "false";
        break;
      case "cols":
        args.cols = Number.parseInt(value, 10);
        break;
      case "rows":
        args.rows = Number.parseInt(value, 10);
        break;
      case "perPage":
        args.perPage = Number.parseInt(value, 10);
        break;
      case "output":
        args.output = value;
        break;
      default:
        break;
    }
  }
  return args;
}

async function resolveProducts(args) {
  if (args.ids && args.ids.length > 0) {
    return listProductsByIds(args.ids);
  }
  if (args.category) {
    return listProductsByCategory(args.category);
  }
  if (args.includeAll) {
    return listActiveProducts();
  }
  throw new Error("No filters provided to generate barcode sheet");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  await connectDB();
  await seedInventoryProducts();

  const products = await resolveProducts(args);
  if (!products.length) {
    throw new Error("No products found for provided filters");
  }

  const buffer = await generateSheetBuffer(products, {
    columns: args.cols,
    rows: args.rows,
    perPage: args.perPage,
  });

  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const outputPath = args.output
    ? path.resolve(process.cwd(), args.output)
    : path.resolve(__dirname, "../../output/hoja_barcodes.pdf");

  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.writeFile(outputPath, buffer);
  console.log(`Barcode sheet generated at ${outputPath}`);
}

main()
  .catch((error) => {
    console.error("Failed to generate barcode sheet", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (AppDataSource?.isInitialized) {
      await AppDataSource.destroy();
    }
  });
