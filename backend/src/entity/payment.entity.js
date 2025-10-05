import { EntitySchema } from "typeorm";

const PaymentSchema = new EntitySchema({
  name: "Payment",
  tableName: "payments",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    status: {
      type: "enum",
      enum: ["pending", "validated", "rejected"],
      default: "pending",
      nullable: false,
    },
    method: {
      type: "enum",
      enum: ["transferencia", "efectivo", "tarjeta", "webpay", "otro"],
      nullable: false,
    },
    amount: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
    },
    referenceCode: {
      type: "varchar",
      length: 50,
      nullable: true,
      unique: true,
    },
    paidAt: {
      type: "date",
      nullable: true,
    },
    dueDate: {
      type: "date",
      nullable: true,
    },
    voucherUrl: {
      type: "varchar",
      length: 255,
      nullable: true,
    },
    comments: {
      type: "text",
      nullable: true,
    },
    rejectionReason: {
      type: "text",
      nullable: true,
    },
    reviewedAt: {
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
    { name: "IDX_PAYMENTS_STATUS", columns: ["status"] },
    { name: "IDX_PAYMENTS_METHOD", columns: ["method"] },
    { name: "IDX_PAYMENTS_ENROLLMENT", columns: ["enrollmentId"] },
  ],
  relations: {
    enrollment: {
      type: "many-to-one",
      target: "Enrollment",
      joinColumn: { name: "enrollmentId", referencedColumnName: "id" },
      nullable: false,
      onDelete: "CASCADE",
    },
    submittedBy: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "submittedById", referencedColumnName: "id" },
      nullable: false,
      onDelete: "RESTRICT",
    },
    reviewedBy: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "reviewedById", referencedColumnName: "id" },
      nullable: true,
      onDelete: "SET NULL",
    },
  },
});

export default PaymentSchema;