import { TableColumn } from "typeorm";

export class AlterEstudiantesAddPagosPorAnio20260301000000 {
  async up(queryRunner) {
    // Añadir columna pagosPorAnio si no existe (puede ya existir si fue creada manualmente)
    await queryRunner.query(
      `ALTER TABLE "estudiantes" ADD COLUMN IF NOT EXISTS "pagosPorAnio" jsonb DEFAULT '{}'`
    );
  }

  async down(queryRunner) {
    await queryRunner.query(`ALTER TABLE "estudiantes" DROP COLUMN IF EXISTS "pagosPorAnio"`);
  }
}
