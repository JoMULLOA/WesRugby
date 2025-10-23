"use strict";
import { EntitySchema } from "typeorm";

const UserSchema = new EntitySchema({
  name: "User",
  tableName: "users",
  columns: {
    rut: {
      type: "varchar",
      length: 12,
      primary: true,
      nullable: false,
      unique: true,
    },
    nombreCompleto: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    fechaNacimiento: {
      type: "date",
      nullable: true,
    },
    email: {
      type: "varchar",
      length: 255,
      nullable: false,
      unique: true,
    },
    avatarPath: {
      type: "varchar",
      length: 400,
      nullable: true,
    },
    avatarVersion: {
      type: "int",
      nullable: false,
      default: 0,
    },
    rol: {
      type: "enum",
      enum: ["directiva", "tesorera", "apoderado", "entrenador", "RamaExterna"],
      nullable: false,
    },
    password: {
      type: "varchar",
      nullable: false,
    },
    createdAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      nullable: false,
    },
    updatedAt: {
      type: "timestamp with time zone",
      default: () => "CURRENT_TIMESTAMP",
      onUpdate: "CURRENT_TIMESTAMP",
      nullable: false,
    },
  },
  indices: [
    {
      name: "IDX_USER_RUT",
      columns: ["rut"],
      unique: true,
    },
    {
      name: "IDX_USER_EMAIL",
      columns: ["email"],
      unique: true,
    },
  ],
});

export default UserSchema;
