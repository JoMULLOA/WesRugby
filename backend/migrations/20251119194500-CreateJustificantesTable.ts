import { MigrationInterface, QueryRunner, Table, TableIndex } from "typeorm";

export class CreateJustificantesTable20251119194500 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: "justificantes",
        columns: [
          { name: "id", type: "uuid", isPrimary: true, isGenerated: true, generationStrategy: "uuid" },
          { name: "apoderadoRut", type: "varchar", length: "12", isNullable: false },
          { name: "apoderadoEmail", type: "varchar", length: "255", isNullable: true },
          { name: "estudianteRut", type: "varchar", length: "12", isNullable: false },
          { name: "fechaInicio", type: "date", isNullable: false },
          { name: "fechaFin", type: "date", isNullable: true },
          { name: "tipo", type: "varchar", length: "30", isNullable: false, comment: "Tipo de justificante (medico, academico, etc)" },
          { name: "motivo", type: "text", isNullable: false },
          { name: "descripcion", type: "text", isNullable: true },
          { name: "rutaArchivo", type: "varchar", length: "500", isNullable: true },
          { name: "nombreArchivoOriginal", type: "varchar", length: "255", isNullable: true },
          { name: "tipoArchivo", type: "varchar", length: "50", isNullable: true },
          { name: "tamanoArchivo", type: "int", isNullable: true },
          { name: "estado", type: "varchar", length: "20", isNullable: false, default: "'pendiente'" },
          { name: "motivoRechazo", type: "text", isNullable: true },
          { name: "observacionesDirectiva", type: "text", isNullable: true },
          { name: "revisadoPorRut", type: "varchar", length: "12", isNullable: true },
          { name: "fechaRevision", type: "timestamp with time zone", isNullable: true },
          { name: "fechaSubida", type: "timestamp with time zone", default: "now()" },
          { name: "createdAt", type: "timestamp with time zone", default: "now()" },
          { name: "updatedAt", type: "timestamp with time zone", default: "now()" },
        ],
      }),
      true
    );

    await queryRunner.createIndex(
      "justificantes",
      new TableIndex({ name: "IDX_JUSTIFICANTE_APODERADO", columnNames: ["apoderadoRut"] })
    );
    await queryRunner.createIndex(
      "justificantes",
      new TableIndex({ name: "IDX_JUSTIFICANTE_ESTUDIANTE", columnNames: ["estudianteRut"] })
    );
    await queryRunner.createIndex(
      "justificantes",
      new TableIndex({ name: "IDX_JUSTIFICANTE_ESTADO", columnNames: ["estado"] })
    );
    await queryRunner.createIndex(
      "justificantes",
      new TableIndex({ name: "IDX_JUSTIFICANTE_FECHA_INICIO", columnNames: ["fechaInicio"] })
    );
    await queryRunner.createIndex(
      "justificantes",
      new TableIndex({ name: "IDX_JUSTIFICANTE_FECHA_FIN", columnNames: ["fechaFin"] })
    );

    console.log("✅ Tabla justificantes creada");
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex("justificantes", "IDX_JUSTIFICANTE_FECHA_FIN");
    await queryRunner.dropIndex("justificantes", "IDX_JUSTIFICANTE_FECHA_INICIO");
    await queryRunner.dropIndex("justificantes", "IDX_JUSTIFICANTE_ESTADO");
    await queryRunner.dropIndex("justificantes", "IDX_JUSTIFICANTE_ESTUDIANTE");
    await queryRunner.dropIndex("justificantes", "IDX_JUSTIFICANTE_APODERADO");
    await queryRunner.dropTable("justificantes");
    console.log("✅ Tabla justificantes eliminada");
  }
}
