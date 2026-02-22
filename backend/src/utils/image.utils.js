"use strict";
import fs from "fs";
import sharp from "sharp";

const fsPromises = fs.promises;

const DEFAULT_OPTIONS = Object.freeze({
  maxWidth: 1280,
  maxHeight: 1280,
  quality: 80,
});

const MIME_TO_FORMAT = {
  "image/jpeg": "jpeg",
  "image/jpg": "jpeg",
  "image/png": "png",
  "image/webp": "webp",
  "image/gif": "gif",
};

function normalizeOptions(options = {}) {
  const normalized = { ...DEFAULT_OPTIONS, ...options };

  if (!Number.isFinite(normalized.maxWidth) || normalized.maxWidth <= 0) {
    normalized.maxWidth = DEFAULT_OPTIONS.maxWidth;
  }

  if (!Number.isFinite(normalized.maxHeight) || normalized.maxHeight <= 0) {
    normalized.maxHeight = DEFAULT_OPTIONS.maxHeight;
  }

  if (
    !Number.isFinite(normalized.quality) ||
    normalized.quality <= 0 ||
    normalized.quality > 100
  ) {
    normalized.quality = DEFAULT_OPTIONS.quality;
  }

  return normalized;
}

function mimeTypeToFormat(mimeType) {
  if (!mimeType) {
    return null;
  }

  return MIME_TO_FORMAT[mimeType.toLowerCase()] ?? null;
}

function isGifFormat(metadata, mimeType) {
  const formatFromMeta = metadata?.format?.toLowerCase();
  const formatFromMime = mimeTypeToFormat(mimeType);
  return formatFromMeta === "gif" || formatFromMime === "gif";
}

function applyFormatSettings(instance, format, quality) {
  if (!format) {
    return instance;
  }

  switch (format) {
    case "jpeg":
    case "jpg":
      return instance.jpeg({ quality, mozjpeg: true });
    case "png":
      return instance.png({ compressionLevel: 9, adaptiveFiltering: true });
    case "webp":
      return instance.webp({ quality, effort: 4 });
    default:
      return instance;
  }
}

export async function optimizeImageBuffer(buffer, mimeType, options = {}) {
  if (!buffer || !Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new Error("Buffer de imagen inválido");
  }

  const normalized = normalizeOptions(options);
  const baseImage = sharp(buffer, { failOnError: false });
  const metadata = await baseImage.metadata();

  if (isGifFormat(metadata, mimeType)) {
    return {
      buffer,
      resized: false,
      size: buffer.length,
      width: metadata.width ?? null,
      height: metadata.height ?? null,
      format: metadata.format ?? mimeTypeToFormat(mimeType) ?? null,
      skippedReason: "gif-not-processed",
    };
  }

  const width = metadata.width ?? 0;
  const height = metadata.height ?? 0;
  const needsResize =
    width > normalized.maxWidth || height > normalized.maxHeight;

  if (!needsResize) {
    return {
      buffer,
      resized: false,
      size: buffer.length,
      width,
      height,
      format: metadata.format ?? mimeTypeToFormat(mimeType) ?? null,
      skippedReason: "within-bounds",
    };
  }

  let pipeline = sharp(buffer, { failOnError: false }).rotate().resize({
    width: normalized.maxWidth,
    height: normalized.maxHeight,
    fit: "inside",
    withoutEnlargement: true,
  });

  pipeline = applyFormatSettings(
    pipeline,
    metadata.format ?? mimeTypeToFormat(mimeType) ?? null,
    normalized.quality,
  );

  const optimizedBuffer = await pipeline.toBuffer();
  const optimizedMetadata = await sharp(optimizedBuffer).metadata();

  return {
    buffer: optimizedBuffer,
    resized: true,
    size: optimizedBuffer.length,
    width: optimizedMetadata.width ?? width,
    height: optimizedMetadata.height ?? height,
    format:
      optimizedMetadata.format ??
      metadata.format ??
      mimeTypeToFormat(mimeType) ??
      null,
  };
}

export async function optimizeImageFile(filePath, mimeType, options = {}) {
  if (!filePath) {
    throw new Error("Ruta de archivo inválida");
  }

  const normalized = normalizeOptions(options);
  const statsBefore = await fsPromises.stat(filePath);
  const baseImage = sharp(filePath, { failOnError: false });
  const metadata = await baseImage.metadata();

  if (isGifFormat(metadata, mimeType)) {
    return {
      resized: false,
      size: statsBefore.size,
      width: metadata.width ?? null,
      height: metadata.height ?? null,
      format: metadata.format ?? mimeTypeToFormat(mimeType) ?? null,
      skippedReason: "gif-not-processed",
    };
  }

  const width = metadata.width ?? 0;
  const height = metadata.height ?? 0;
  const needsResize =
    width > normalized.maxWidth || height > normalized.maxHeight;

  if (!needsResize) {
    return {
      resized: false,
      size: statsBefore.size,
      width,
      height,
      format: metadata.format ?? mimeTypeToFormat(mimeType) ?? null,
      skippedReason: "within-bounds",
    };
  }

  let pipeline = sharp(filePath, { failOnError: false }).rotate().resize({
    width: normalized.maxWidth,
    height: normalized.maxHeight,
    fit: "inside",
    withoutEnlargement: true,
  });

  pipeline = applyFormatSettings(
    pipeline,
    metadata.format ?? mimeTypeToFormat(mimeType) ?? null,
    normalized.quality,
  );

  const optimizedBuffer = await pipeline.toBuffer();
  await fsPromises.writeFile(filePath, optimizedBuffer);

  const statsAfter = await fsPromises.stat(filePath);
  const optimizedMetadata = await sharp(optimizedBuffer).metadata();

  return {
    resized: true,
    size: statsAfter.size,
    width: optimizedMetadata.width ?? width,
    height: optimizedMetadata.height ?? height,
    format:
      optimizedMetadata.format ??
      metadata.format ??
      mimeTypeToFormat(mimeType) ??
      null,
  };
}

export async function optimizeUploadedImage(file, options = {}) {
  if (!file || !file.path) {
    throw new Error("Archivo de carga inválido");
  }

  const result = await optimizeImageFile(file.path, file.mimetype, options);

  if (typeof result.size === "number") {
    file.size = result.size;
  }

  if (typeof result.width === "number") {
    file.width = result.width;
  }

  if (typeof result.height === "number") {
    file.height = result.height;
  }

  return result;
}
