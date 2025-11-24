import { MigrationInterface, QueryRunner } from "typeorm";

export class AlterJustificantesAddMesesExencion20251120093000 implements MigrationInterface {
  name = 'AlterJustificantesAddMesesExencion20251120093000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // jsonb para almacenar array de meses exentos (YYYY-MM)
    await queryRunner.query(`ALTER TABLE justificantes ADD COLUMN "mesesExencion" jsonb NULL`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE justificantes DROP COLUMN "mesesExencion"`);
  }
}
