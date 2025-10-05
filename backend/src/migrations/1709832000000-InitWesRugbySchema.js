export class InitWesRugbySchema1709832000000 {
  name = "InitWesRugbySchema1709832000000";

  async up(queryRunner) {
    await queryRunner.query(CREATE EXTENSION IF NOT EXISTS "pgcrypto");

    await queryRunner.query(CREATE TYPE "public"."users_genero_enum" AS ENUM('masculino','femenino','no_binario','prefiero_no_decir'));
    await queryRunner.query(CREATE TYPE "public"."users_rol_enum" AS ENUM('directiva','tesorera','apoderado','entrenador','administrador'));
    await queryRunner.query(CREATE TYPE "public"."users_estado_enum" AS ENUM('activo','inactivo','bloqueado'));

    await queryRunner.query(CREATE TABLE "users" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "rut" character varying(12) NOT NULL,
      "nombreCompleto" character varying(255) NOT NULL,
      "fechaNacimiento" date,
      "genero" "public"."users_genero_enum" NOT NULL,
      "carrera" character varying(100),
      "telefono" character varying(20),
      "altura" integer,
      "peso" integer,
      "descripcion" text,
      "clasificacion" double precision,
      "cantidadValoraciones" integer NOT NULL DEFAULT 0,
      "puntuacion" integer,
      "contadorReportes" integer NOT NULL DEFAULT 0,
      "email" character varying(255) NOT NULL,
      "rol" "public"."users_rol_enum" NOT NULL,
      "password" character varying(255) NOT NULL,
      "fcmToken" text,
      "saldo" numeric(10,2) NOT NULL DEFAULT 0,
      "tarjetas" jsonb,
      "estado" "public"."users_estado_enum" NOT NULL DEFAULT 'activo',
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "deletedAt" TIMESTAMP WITH TIME ZONE,
      CONSTRAINT "PK_users_id" PRIMARY KEY ("id"),
      CONSTRAINT "UQ_users_rut" UNIQUE ("rut"),
      CONSTRAINT "UQ_users_email" UNIQUE ("email")
    ));

    await queryRunner.query(CREATE INDEX "IDX_USERS_ROL" ON "users" ("rol"));
    await queryRunner.query(CREATE INDEX "IDX_USERS_ESTADO" ON "users" ("estado"));

    await queryRunner.query(CREATE TYPE "public"."players_gender_enum" AS ENUM('masculino','femenino','no_binario','otro'));

    await queryRunner.query(CREATE TABLE "players" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "rut" character varying(12) NOT NULL,
      "firstName" character varying(80) NOT NULL,
      "lastName" character varying(120) NOT NULL,
      "birthDate" date NOT NULL,
      "gender" "public"."players_gender_enum" NOT NULL,
      "schoolGrade" character varying(30),
      "medicalNotes" text,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "guardianId" uuid NOT NULL,
      CONSTRAINT "PK_players_id" PRIMARY KEY ("id"),
      CONSTRAINT "UQ_players_rut" UNIQUE ("rut"),
      CONSTRAINT "FK_players_guardian" FOREIGN KEY ("guardianId") REFERENCES "users"("id") ON DELETE CASCADE
    ));

    await queryRunner.query(CREATE INDEX "IDX_PLAYERS_GUARDIAN" ON "players" ("guardianId"));

    await queryRunner.query(CREATE TYPE "public"."payment_plans_frequency_enum" AS ENUM('mensual','trimestral','anual'));

    await queryRunner.query(CREATE TABLE "payment_plans" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "name" character varying(100) NOT NULL,
      "amount" numeric(10,2) NOT NULL,
      "frequency" "public"."payment_plans_frequency_enum" NOT NULL,
      "isActive" boolean NOT NULL DEFAULT true,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      CONSTRAINT "PK_payment_plans_id" PRIMARY KEY ("id"),
      CONSTRAINT "UQ_payment_plans_name" UNIQUE ("name")
    ));

    await queryRunner.query(CREATE TYPE "public"."enrollments_status_enum" AS ENUM('pending','active','inactive','withdrawn'));

    await queryRunner.query(CREATE TABLE "enrollments" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "season" character varying(9) NOT NULL,
      "status" "public"."enrollments_status_enum" NOT NULL DEFAULT 'pending',
      "notes" text,
      "approvedAt" TIMESTAMP WITH TIME ZONE,
      "withdrawnAt" TIMESTAMP WITH TIME ZONE,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "playerId" uuid NOT NULL,
      "planId" uuid,
      "createdById" uuid NOT NULL,
      "approvedById" uuid,
      CONSTRAINT "PK_enrollments_id" PRIMARY KEY ("id"),
      CONSTRAINT "FK_enrollments_player" FOREIGN KEY ("playerId") REFERENCES "players"("id") ON DELETE CASCADE,
      CONSTRAINT "FK_enrollments_plan" FOREIGN KEY ("planId") REFERENCES "payment_plans"("id") ON DELETE SET NULL,
      CONSTRAINT "FK_enrollments_createdBy" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE RESTRICT,
      CONSTRAINT "FK_enrollments_approvedBy" FOREIGN KEY ("approvedById") REFERENCES "users"("id") ON DELETE SET NULL
    ));

    await queryRunner.query(CREATE INDEX "IDX_ENROLLMENTS_SEASON" ON "enrollments" ("season"));
    await queryRunner.query(CREATE INDEX "IDX_ENROLLMENTS_STATUS" ON "enrollments" ("status"));
    await queryRunner.query(CREATE INDEX "IDX_ENROLLMENTS_PLAYER" ON "enrollments" ("playerId"));
    await queryRunner.query(CREATE INDEX "IDX_ENROLLMENTS_PLAN" ON "enrollments" ("planId"));

    await queryRunner.query(CREATE TYPE "public"."payments_status_enum" AS ENUM('pending','validated','rejected'));
    await queryRunner.query(CREATE TYPE "public"."payments_method_enum" AS ENUM('transferencia','efectivo','tarjeta','webpay','otro'));

    await queryRunner.query(CREATE TABLE "payments" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "status" "public"."payments_status_enum" NOT NULL DEFAULT 'pending',
      "method" "public"."payments_method_enum" NOT NULL,
      "amount" numeric(10,2) NOT NULL,
      "referenceCode" character varying(50),
      "paidAt" date,
      "dueDate" date,
      "voucherUrl" character varying(255),
      "comments" text,
      "rejectionReason" text,
      "reviewedAt" TIMESTAMP WITH TIME ZONE,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "enrollmentId" uuid NOT NULL,
      "submittedById" uuid NOT NULL,
      "reviewedById" uuid,
      CONSTRAINT "PK_payments_id" PRIMARY KEY ("id"),
      CONSTRAINT "UQ_payments_reference" UNIQUE ("referenceCode"),
      CONSTRAINT "FK_payments_enrollment" FOREIGN KEY ("enrollmentId") REFERENCES "enrollments"("id") ON DELETE CASCADE,
      CONSTRAINT "FK_payments_submittedBy" FOREIGN KEY ("submittedById") REFERENCES "users"("id") ON DELETE RESTRICT,
      CONSTRAINT "FK_payments_reviewedBy" FOREIGN KEY ("reviewedById") REFERENCES "users"("id") ON DELETE SET NULL
    ));

    await queryRunner.query(CREATE INDEX "IDX_PAYMENTS_STATUS" ON "payments" ("status"));
    await queryRunner.query(CREATE INDEX "IDX_PAYMENTS_METHOD" ON "payments" ("method"));
    await queryRunner.query(CREATE INDEX "IDX_PAYMENTS_ENROLLMENT" ON "payments" ("enrollmentId"));

    await queryRunner.query(CREATE TYPE "public"."notifications_channel_enum" AS ENUM('in_app','email','push'));

    await queryRunner.query(CREATE TABLE "notifications" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "title" character varying(120) NOT NULL,
      "message" text NOT NULL,
      "channel" "public"."notifications_channel_enum" NOT NULL DEFAULT 'in_app',
      "payload" jsonb,
      "sentAt" TIMESTAMP WITH TIME ZONE,
      "readAt" TIMESTAMP WITH TIME ZONE,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "recipientId" uuid NOT NULL,
      CONSTRAINT "PK_notifications_id" PRIMARY KEY ("id"),
      CONSTRAINT "FK_notifications_recipient" FOREIGN KEY ("recipientId") REFERENCES "users"("id") ON DELETE CASCADE
    ));

    await queryRunner.query(CREATE INDEX "IDX_NOTIFICATIONS_RECIPIENT" ON "notifications" ("recipientId"));
    await queryRunner.query(CREATE INDEX "IDX_NOTIFICATIONS_CHANNEL" ON "notifications" ("channel"));

    await queryRunner.query(CREATE TYPE "public"."attendance_activity_type_enum" AS ENUM('entrenamiento','partido','evento'));
    await queryRunner.query(CREATE TYPE "public"."attendance_status_enum" AS ENUM('presente','ausente','tarde','justificado'));

    await queryRunner.query(CREATE TABLE "attendance_records" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "activityDate" date NOT NULL,
      "activityType" "public"."attendance_activity_type_enum" NOT NULL,
      "status" "public"."attendance_status_enum" NOT NULL,
      "notes" text,
      "recordedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "enrollmentId" uuid NOT NULL,
      "recordedById" uuid NOT NULL,
      CONSTRAINT "PK_attendance_records_id" PRIMARY KEY ("id"),
      CONSTRAINT "FK_attendance_enrollment" FOREIGN KEY ("enrollmentId") REFERENCES "enrollments"("id") ON DELETE CASCADE,
      CONSTRAINT "FK_attendance_recordedBy" FOREIGN KEY ("recordedById") REFERENCES "users"("id") ON DELETE RESTRICT
    ));

    await queryRunner.query(CREATE INDEX "IDX_ATTENDANCE_ENROLLMENT" ON "attendance_records" ("enrollmentId"));
    await queryRunner.query(CREATE INDEX "IDX_ATTENDANCE_DATE" ON "attendance_records" ("activityDate"));

    await queryRunner.query(CREATE TABLE "inventory_items" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "sku" character varying(40) NOT NULL,
      "name" character varying(120) NOT NULL,
      "description" text,
      "stock" integer NOT NULL DEFAULT 0,
      "unitPrice" numeric(10,2) NOT NULL,
      "isActive" boolean NOT NULL DEFAULT true,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      CONSTRAINT "PK_inventory_items_id" PRIMARY KEY ("id"),
      CONSTRAINT "UQ_inventory_items_sku" UNIQUE ("sku")
    ));

    await queryRunner.query(CREATE INDEX "IDX_INVENTORY_ITEMS_ACTIVE" ON "inventory_items" ("isActive"));

    await queryRunner.query(CREATE TABLE "inventory_sales" (
      "id" uuid NOT NULL DEFAULT gen_random_uuid(),
      "quantity" integer NOT NULL,
      "totalAmount" numeric(10,2) NOT NULL,
      "soldAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "buyerName" character varying(150),
      "notes" text,
      "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
      "itemId" uuid NOT NULL,
      "soldById" uuid NOT NULL,
      CONSTRAINT "PK_inventory_sales_id" PRIMARY KEY ("id"),
      CONSTRAINT "FK_inventory_sales_item" FOREIGN KEY ("itemId") REFERENCES "inventory_items"("id") ON DELETE CASCADE,
      CONSTRAINT "FK_inventory_sales_soldBy" FOREIGN KEY ("soldById") REFERENCES "users"("id") ON DELETE RESTRICT
    ));

    await queryRunner.query(CREATE INDEX "IDX_INVENTORY_SALES_ITEM" ON "inventory_sales" ("itemId"));
    await queryRunner.query(CREATE INDEX "IDX_INVENTORY_SALES_SOLD_AT" ON "inventory_sales" ("soldAt"));
  }

  async down(queryRunner) {
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_INVENTORY_SALES_SOLD_AT");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_INVENTORY_SALES_ITEM");
    await queryRunner.query(DROP TABLE IF EXISTS "inventory_sales");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_INVENTORY_ITEMS_ACTIVE");
    await queryRunner.query(DROP TABLE IF EXISTS "inventory_items");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_ATTENDANCE_DATE");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_ATTENDANCE_ENROLLMENT");
    await queryRunner.query(DROP TABLE IF EXISTS "attendance_records");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."attendance_status_enum");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."attendance_activity_type_enum");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_NOTIFICATIONS_CHANNEL");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_NOTIFICATIONS_RECIPIENT");
    await queryRunner.query(DROP TABLE IF EXISTS "notifications");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."notifications_channel_enum");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_PAYMENTS_ENROLLMENT");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_PAYMENTS_METHOD");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_PAYMENTS_STATUS");
    await queryRunner.query(DROP TABLE IF EXISTS "payments");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."payments_method_enum");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."payments_status_enum");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_ENROLLMENTS_PLAN");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_ENROLLMENTS_PLAYER");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_ENROLLMENTS_STATUS");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_ENROLLMENTS_SEASON");
    await queryRunner.query(DROP TABLE IF EXISTS "enrollments");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."enrollments_status_enum");

    await queryRunner.query(DROP TABLE IF EXISTS "payment_plans");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."payment_plans_frequency_enum");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_PLAYERS_GUARDIAN");
    await queryRunner.query(DROP TABLE IF EXISTS "players");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."players_gender_enum");

    await queryRunner.query(DROP INDEX IF EXISTS "IDX_USERS_ESTADO");
    await queryRunner.query(DROP INDEX IF EXISTS "IDX_USERS_ROL");
    await queryRunner.query(DROP TABLE IF EXISTS "users");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."users_estado_enum");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."users_rol_enum");
    await queryRunner.query(DROP TYPE IF EXISTS "public"."users_genero_enum");
  }
}