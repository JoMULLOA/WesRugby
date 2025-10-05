import { EntitySchema } from "typeorm";

const AttendanceRecordSchema = new EntitySchema({
  name: "AttendanceRecord",
  tableName: "attendance_records",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    activityDate: {
      type: "date",
      nullable: false,
    },
    activityType: {
      type: "enum",
      enum: ["entrenamiento", "partido", "evento"],
      nullable: false,
    },
    status: {
      type: "enum",
      enum: ["presente", "ausente", "tarde", "justificado"],
      nullable: false,
    },
    notes: {
      type: "text",
      nullable: true,
    },
    recordedAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
    updatedAt: {
      type: "timestamp with time zone",
      updateDate: true,
    },
  },
  indices: [
    { name: "IDX_ATTENDANCE_ENROLLMENT", columns: ["enrollmentId"] },
    { name: "IDX_ATTENDANCE_DATE", columns: ["activityDate"] },
  ],
  relations: {
    enrollment: {
      type: "many-to-one",
      target: "Enrollment",
      joinColumn: { name: "enrollmentId", referencedColumnName: "id" },
      nullable: false,
      onDelete: "CASCADE",
    },
    recordedBy: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "recordedById", referencedColumnName: "id" },
      nullable: false,
      onDelete: "RESTRICT",
    },
  },
});

export default AttendanceRecordSchema;