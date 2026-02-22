import "reflect-metadata";
import { AppDataSource } from "./src/config/configDb.js";

async function runMigrations() {
  try {
    console.log("🔄 Inicializando conexión a la base de datos...");
    await AppDataSource.initialize();
    console.log("✅ Conexión establecida");

    console.log("🔄 Ejecutando migraciones pendientes...");
    const migrations = await AppDataSource.runMigrations({
      transaction: "all",
    });

    if (migrations.length === 0) {
      console.log("ℹ️  No hay migraciones pendientes");
    } else {
      console.log(`✅ ${migrations.length} migración(es) ejecutada(s):`);
      migrations.forEach((migration) => {
        console.log(`   - ${migration.name}`);
      });
    }

    await AppDataSource.destroy();
    console.log("✅ Proceso completado");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error ejecutando migraciones:", error);
    process.exit(1);
  }
}

runMigrations();
