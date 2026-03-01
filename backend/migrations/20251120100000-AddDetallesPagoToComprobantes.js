import { TableColumn } from "typeorm";

export class AddDetallesPagoToComprobantes20251120100000 {
  async up(queryRunner) {
    // Agregar campo para almacenar múltiples estudiantes (RUTs)
    await queryRunner.addColumn(
      "comprobantes_pago",
      new TableColumn({
        name: "estudiantes_ruts",
        type: "jsonb",
        isNullable: true,
        comment: "Array de RUTs de estudiantes incluidos en el pago (para pagos agrupados)",
      })
    );

    // Agregar campo para almacenar múltiples meses
    await queryRunner.addColumn(
      "comprobantes_pago",
      new TableColumn({
        name: "meses_correspondientes",
        type: "jsonb",
        isNullable: true,
        comment: "Array de meses incluidos en el pago (formato canónico YYYY-MM, ej: 2026-07)",
      })
    );

    // Agregar campo para detalles del pago por estudiante y mes
    await queryRunner.addColumn(
      "comprobantes_pago",
      new TableColumn({
        name: "detalles_pago",
        type: "jsonb",
        isNullable: true,
        comment: "Detalles del pago: { estudianteRut: { meses: [...], monto: X }, ... }",
      })
    );

    console.log("✅ Columnas agregadas: estudiantes_ruts, meses_correspondientes, detalles_pago");
  }

  async down(queryRunner) {
    await queryRunner.dropColumn("comprobantes_pago", "detalles_pago");
    await queryRunner.dropColumn("comprobantes_pago", "meses_correspondientes");
    await queryRunner.dropColumn("comprobantes_pago", "estudiantes_ruts");
    
    console.log("✅ Columnas eliminadas: estudiantes_ruts, meses_correspondientes, detalles_pago");
  }
}
