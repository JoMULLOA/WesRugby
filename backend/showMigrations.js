import "reflect-metadata";
import { AppDataSource } from "./src/config/configDb.js";

async function showMigrations() {
  try {
    console.log("🔄 Inicializando conexión a la base de datos...");
    await AppDataSource.initialize();
    console.log("✅ Conexión establecida\n");

    const executedMigrations = await AppDataSource.query(
      `SELECT * FROM migrations_history ORDER BY timestamp DESC`
    );

    console.log("📋 Migraciones ejecutadas:");
    if (executedMigrations.length === 0) {
      console.log("   (ninguna)");
    } else {
      executedMigrations.forEach((m) => {
        const date = new Date(parseInt(m.timestamp));
        console.log(`   ✓ ${m.name} (${date.toLocaleString()})`);
      });
    }

    console.log("\n📁 Migraciones pendientes:");
    const pendingMigrations = await AppDataSource.showMigrations();
    if (!pendingMigrations) {
      console.log("   (ninguna)");
    } else {
      console.log("   Hay migraciones sin ejecutar");
    }

    await AppDataSource.destroy();
    console.log("\n✅ Proceso completado");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error mostrando migraciones:", error);
    process.exit(1);
  }
}

showMigrations();
