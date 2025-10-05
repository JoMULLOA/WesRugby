import { EntitySchema } from "typeorm";

const EnrollmentSchema = new EntitySchema({
  name: "Enrollment",
  tableName: "enrollments",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    season: {
      type: "varchar",
      length: 9,
      nullable: false,
    },
    status: {
      type: "enum",
      enum: ["pending", "active", "inactive", "withdrawn"],
      default: "pending",
      nullable: false,
    },
    notes: {
      type: "text",
      nullable: true,
    },
    approvedAt: {
      type: "timestamp with time zone",
      nullable: true,
    },
    withdrawnAt: {
      type: "timestamp with time zone",
      nullable: true,
    },
    createdAt: {
      type: "timestamp with time zone",
      createDate: true,
    },
    updatedAt: {
      type: "timestamp with time zone",
      updateDate: true,
    },
  },
  indices: [
    { name: "IDX_ENROLLMENTS_SEASON", columns: ["season"] },
    { name: "IDX_ENROLLMENTS_STATUS", columns: ["status"] },
    { name: "IDX_ENROLLMENTS_PLAYER", columns: ["playerId"] },
    { name: "IDX_ENROLLMENTS_PLAN", columns: ["planId"] },
  ],
  relations: {
    player: {
      type: "many-to-one",
      target: "Player",
      joinColumn: { name: "playerId", referencedColumnName: "id" },
      nullable: false,
      onDelete: "CASCADE",
    },
    plan: {
      type: "many-to-one",
      target: "PaymentPlan",
      joinColumn: { name: "planId", referencedColumnName: "id" },
      nullable: true,
      onDelete: "SET NULL",
    },
    createdBy: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "createdById", referencedColumnName: "id" },
      nullable: false,
      onDelete: "RESTRICT",
    },
    approvedBy: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "approvedById", referencedColumnName: "id" },
      nullable: true,
      onDelete: "SET NULL",
    },
    attendanceRecords: {
      type: "one-to-many",
      target: "AttendanceRecord",
      inverseSide: "enrollment",
    },
    payments: {
      type: "one-to-many",
      target: "Payment",
      inverseSide: "enrollment",
    },
  },
});

export default EnrollmentSchema;