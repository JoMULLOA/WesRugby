import { MigrationInterface, QueryRunner } from "typeorm";

export class AlterComprobantesPagoAddAnioMatricula20251119163000 implements MigrationInterface {
  name = "AlterComprobantesPagoAddAnioMatricula20251119163000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "comprobantes_pago" ADD COLUMN "anioMatricula" integer`);
    await queryRunner.query(`ALTER TABLE "comprobantes_pago" ALTER COLUMN "tipoArchivo" TYPE varchar(50)`);
    await queryRunner.query(`CREATE INDEX "IDX_COMPROBANTE_ANIO_MATRICULA" ON "comprobantes_pago" ("anioMatricula")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_COMPROBANTE_ANIO_MATRICULA"`);
    await queryRunner.query(`ALTER TABLE "comprobantes_pago" ALTER COLUMN "tipoArchivo" TYPE varchar(20)`);
    await queryRunner.query(`ALTER TABLE "comprobantes_pago" DROP COLUMN "anioMatricula"`);
  }
}
