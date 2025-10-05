import { EntitySchema } from "typeorm";

const PaymentPlanSchema = new EntitySchema({
  name: "PaymentPlan",
  tableName: "payment_plans",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    name: {
      type: "varchar",
      length: 100,
      nullable: false,
    },
    amount: {
      type: "decimal",
      precision: 10,
      scale: 2,
      nullable: false,
    },
    frequency: {
      type: "enum",
      enum: ["mensual", "trimestral", "anual"],
      nullable: false,
    },
    isActive: {
      type: "boolean",
      default: true,
      nullable: false,
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
    { name: "IDX_PAYMENT_PLANS_ACTIVE", columns: ["isActive"] },
    { name: "IDX_PAYMENT_PLANS_NAME", columns: ["name"], unique: true },
  ],
  relations: {
    enrollments: {
      type: "one-to-many",
      target: "Enrollment",
      inverseSide: "plan",
    },
  },
});

export default PaymentPlanSchema;