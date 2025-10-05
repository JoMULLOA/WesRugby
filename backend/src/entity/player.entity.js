import { EntitySchema } from "typeorm";

const PlayerSchema = new EntitySchema({
  name: "Player",
  tableName: "players",
  columns: {
    id: {
      type: "uuid",
      primary: true,
      generated: "uuid",
    },
    rut: {
      type: "varchar",
      length: 12,
      unique: true,
      nullable: false,
    },
    firstName: {
      type: "varchar",
      length: 80,
      nullable: false,
    },
    lastName: {
      type: "varchar",
      length: 120,
      nullable: false,
    },
    birthDate: {
      type: "date",
      nullable: false,
    },
    gender: {
      type: "enum",
      enum: ["masculino", "femenino", "no_binario", "otro"],
      nullable: false,
    },
    schoolGrade: {
      type: "varchar",
      length: 30,
      nullable: true,
    },
    medicalNotes: {
      type: "text",
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
    { name: "IDX_PLAYERS_RUT", columns: ["rut"], unique: true },
    { name: "IDX_PLAYERS_GUARDIAN", columns: ["guardianId"] },
  ],
  relations: {
    guardian: {
      type: "many-to-one",
      target: "User",
      joinColumn: {
        name: "guardianId",
        referencedColumnName: "id",
      },
      nullable: false,
      onDelete: "CASCADE",
    },
    enrollments: {
      type: "one-to-many",
      target: "Enrollment",
      inverseSide: "player",
    },
  },
});

export default PlayerSchema;