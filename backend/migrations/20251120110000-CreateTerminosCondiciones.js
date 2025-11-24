export class CreateTerminosCondiciones20251120110000 {
  async up(queryRunner) {
    // Verificar si la tabla terminos_condiciones existe
    const terminosTable = await queryRunner.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'terminos_condiciones'
      );
    `);

    if (!terminosTable[0].exists) {
      // Tabla para almacenar versiones de términos y condiciones
      await queryRunner.query(`
        CREATE TABLE "terminos_condiciones" (
          "id" SERIAL PRIMARY KEY,
          "version" VARCHAR(20) NOT NULL,
          "titulo" VARCHAR(255) NOT NULL,
          "contenido" TEXT NOT NULL,
          "activo" BOOLEAN DEFAULT true,
          "creadoPorRut" VARCHAR(12) NOT NULL,
          "fechaCreacion" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "fechaActivacion" TIMESTAMP,
          "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log("✅ Tabla terminos_condiciones creada");
    } else {
      console.log("ℹ️  Tabla terminos_condiciones ya existe");
    }

    // Verificar si la tabla aceptaciones_terminos existe
    const aceptacionesTable = await queryRunner.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'aceptaciones_terminos'
      );
    `);

    if (!aceptacionesTable[0].exists) {
      // Tabla para registrar aceptaciones de apoderados
      await queryRunner.query(`
        CREATE TABLE "aceptaciones_terminos" (
          "id" SERIAL PRIMARY KEY,
          "apoderadoRut" VARCHAR(12) NOT NULL,
          "terminoId" INTEGER NOT NULL,
          "version" VARCHAR(20) NOT NULL,
          "fechaAceptacion" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "ipAddress" VARCHAR(45),
          "userAgent" TEXT,
          "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT "FK_aceptaciones_terminos_termino" 
            FOREIGN KEY ("terminoId") 
            REFERENCES "terminos_condiciones"("id") 
            ON DELETE CASCADE
        )
      `);
      console.log("✅ Tabla aceptaciones_terminos creada");
    } else {
      console.log("ℹ️  Tabla aceptaciones_terminos ya existe");
    }

    // Crear índices si no existen
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_terminos_activo" 
      ON "terminos_condiciones"("activo");
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_aceptaciones_apoderado" 
      ON "aceptaciones_terminos"("apoderadoRut");
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_aceptaciones_termino" 
      ON "aceptaciones_terminos"("terminoId");
    `);

    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "UQ_apoderado_termino" 
      ON "aceptaciones_terminos"("apoderadoRut", "terminoId");
    `);

    console.log("✅ Índices de términos y condiciones verificados");
  }

  async down(queryRunner) {
    await queryRunner.query(`DROP TABLE "aceptaciones_terminos"`);
    await queryRunner.query(`DROP TABLE "terminos_condiciones"`);
    
    console.log("✅ Tablas de términos y condiciones eliminadas");
  }
}
