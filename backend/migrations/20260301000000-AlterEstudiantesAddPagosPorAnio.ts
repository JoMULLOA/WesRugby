import { MigrationInterface, QueryRunner } from "typeorm";

export class AlterEstudiantesAddPagosPorAnio20260301000000 implements MigrationInterface {
  name = "AlterEstudiantesAddPagosPorAnio20260301000000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Añadir columna pagosPorAnio como JSONB
    await queryRunner.query(
      `ALTER TABLE "estudiantes" ADD COLUMN IF NOT EXISTS "pagosPorAnio" jsonb NOT NULL DEFAULT '{}'`
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "estudiantes" DROP COLUMN IF EXISTS "pagosPorAnio"`);
  }
}
