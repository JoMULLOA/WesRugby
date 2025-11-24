export class AlterMesCorrespondienteLength20251120104000 {
  async up(queryRunner) {
    // Aumentar el tamaño del campo mesCorrespondiente de VARCHAR(7) a VARCHAR(50)
    // para soportar valores como "Multiple" o labels completos como "Agosto 2025"
    await queryRunner.query(`
      ALTER TABLE "comprobantes_pago" 
      ALTER COLUMN "mesCorrespondiente" 
      TYPE VARCHAR(50)
    `);

    console.log("✅ Campo mesCorrespondiente ampliado a VARCHAR(50)");
  }

  async down(queryRunner) {
    // Revertir a VARCHAR(7) (solo si los datos lo permiten)
    await queryRunner.query(`
      ALTER TABLE "comprobantes_pago" 
      ALTER COLUMN "mesCorrespondiente" 
      TYPE VARCHAR(7)
    `);
    
    console.log("✅ Campo mesCorrespondiente revertido a VARCHAR(7)");
  }
}
