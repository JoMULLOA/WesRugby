import { MigrationInterface, QueryRunner, Table, TableIndex } from "typeorm";

export class CreateConfiguracionPreciosTable20251107094056 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: "configuracion_precios",
        columns: [
          {
            name: "id",
            type: "int",
            isPrimary: true,
            isGenerated: true,
            generationStrategy: "increment",
          },
          {
            name: "anio",
            type: "int",
            isNullable: false,
          },
          {
            name: "precioMensualidad",
            type: "decimal",
            precision: 10,
            scale: 2,
            isNullable: false,
          },
          {
            name: "descuentoMensualidad2",
            type: "int",
            isNullable: false,
            default: 0,
            comment: "Descuento en porcentaje para 2 estudiantes (0-100) aplicado sobre la suma total",
          },
          {
            name: "descuentoMensualidad3Plus",
            type: "int",
            isNullable: false,
            default: 0,
            comment: "Descuento en porcentaje para 3 o más estudiantes (0-100)",
          },
          {
            name: "precioMatricula",
            type: "decimal",
            precision: 10,
            scale: 2,
            isNullable: false,
          },
          {
            name: "descuentoMatricula2",
            type: "int",
            isNullable: false,
            default: 0,
            comment: "Descuento en porcentaje para 2 estudiantes (0-100) aplicado sobre la suma total",
          },
          {
            name: "descuentoMatricula3Plus",
            type: "int",
            isNullable: false,
            default: 0,
            comment: "Descuento en porcentaje para 3 o más estudiantes (0-100)",
          },
          {
            name: "fechaCreacion",
            type: "timestamp with time zone",
            default: "now()",
          },
          {
            name: "fechaActualizacion",
            type: "timestamp with time zone",
            default: "now()",
          },
        ],
      }),
      true
    );

    // Crear índice único en el año
    await queryRunner.createIndex(
      "configuracion_precios",
      new TableIndex({
        name: "IDX_CONFIGURACION_PRECIO_ANIO",
        columnNames: ["anio"],
        isUnique: true,
      })
    );

    console.log("✅ Tabla configuracion_precios creada exitosamente");
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex("configuracion_precios", "IDX_CONFIGURACION_PRECIO_ANIO");
    await queryRunner.dropTable("configuracion_precios");
    console.log("✅ Tabla configuracion_precios eliminada exitosamente");
  }
}
