"use strict";
import { S3Client } from "@aws-sdk/client-s3";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, ".env") });

export const s3Client = new S3Client({
  region: process.env.S3_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS,
    secretAccessKey: process.env.AWS_SECRET,
  },
});
