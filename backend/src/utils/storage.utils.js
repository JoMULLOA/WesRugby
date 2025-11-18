"use strict";
import { DeleteObjectCommand } from "@aws-sdk/client-s3";
import { s3Client } from "../config/s3.js";

const bucket = process.env.S3_BUCKET;
const region = process.env.S3_REGION;
const publicBase =
  process.env.S3_PUBLIC_URL ||
  (bucket && region ? `https://${bucket}.s3.${region}.amazonaws.com` : null);

export function resolveFileUrl(value, req) {
  if (!value) {
    return null;
  }

  if (/^https?:\/\//i.test(value)) {
    return value;
  }

  if (publicBase) {
    return `${publicBase}/${value.replace(/^\/+/, "")}`;
  }

  if (req) {
    const baseUrl = `${req.protocol}://${req.get("host")}`;
    return `${baseUrl}/${value.replace(/^\/+/, "")}`;
  }

  return value;
}

export function extractObjectKey(pathOrUrl) {
  if (!pathOrUrl) return null;
  if (/^https?:\/\//i.test(pathOrUrl)) {
    try {
      const url = new URL(pathOrUrl);
      return decodeURIComponent(url.pathname.replace(/^\/+/, ""));
    } catch {
      return null;
    }
  }
  return pathOrUrl.replace(/^\/+/, "");
}

export async function deleteFromS3(pathOrUrl) {
  try {
    const key = extractObjectKey(pathOrUrl);
    if (!key || !bucket) {
      return;
    }
    await s3Client.send(
      new DeleteObjectCommand({
        Bucket: bucket,
        Key: key,
      }),
    );
  } catch (error) {
    console.warn("No se pudo eliminar archivo remoto:", error.message);
  }
}
