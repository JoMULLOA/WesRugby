import { EntitySchema } from "typeorm";

const NotificationSchema = new EntitySchema({
  name: "Notification",
  tableName: "notifications",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    title: {
      type: "varchar",
      length: 120,
      nullable: false,
    },
    message: {
      type: "text",
      nullable: false,
    },
    channel: {
      type: "enum",
      enum: ["in_app", "email", "push"],
      default: "in_app",
      nullable: false,
    },
    payload: {
      type: "jsonb",
      nullable: true,
    },
    sentAt: {
      type: "timestamp with time zone",
      nullable: true,
    },
    readAt: {
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
    { name: "IDX_NOTIFICATIONS_RECIPIENT", columns: ["recipientId"] },
    { name: "IDX_NOTIFICATIONS_CHANNEL", columns: ["channel"] },
    { name: "IDX_NOTIFICATIONS_SENT_AT", columns: ["sentAt"] },
  ],
  relations: {
    recipient: {
      type: "many-to-one",
      target: "User",
      joinColumn: { name: "recipientId", referencedColumnName: "id" },
      nullable: false,
      onDelete: "CASCADE",
    },
  },
});

export default NotificationSchema;