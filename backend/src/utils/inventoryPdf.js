"use strict";
import PDFDocument from "pdfkit";
import bwipjs from "bwip-js";

function renderBarcode(text) {
  return bwipjs.toBuffer({
    bcid: "code128",
    text,
    scale: 3,
    height: 12,
    includetext: false,
    textxalign: "center",
  });
}

export async function generateBarcodeSheet(labels, options = {}) {
  const columns = Number.isInteger(options.columns) ? options.columns : 3;
  const rows = Number.isInteger(options.rows) ? options.rows : 8;
  const perPage = options.perPage && options.perPage > 0 ? options.perPage : columns * rows;

  const doc = new PDFDocument({
    size: "A4",
    margins: { top: 36, bottom: 36, left: 36, right: 36 },
    autoFirstPage: true,
  });

  const chunks = [];
  doc.on("data", (chunk) => chunks.push(chunk));

  const usableWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right;
  const usableHeight = doc.page.height - doc.page.margins.top - doc.page.margins.bottom;
  const cellWidth = usableWidth / columns;
  const cellHeight = usableHeight / rows;

  for (let index = 0; index < labels.length; index += 1) {
    const label = labels[index];
    if (index > 0 && index % perPage === 0) {
      doc.addPage();
    }

    const position = index % perPage;
    const column = position % columns;
    const row = Math.floor(position / columns);

    const originX = doc.page.margins.left + column * cellWidth;
    const originY = doc.page.margins.top + row * cellHeight;

    // Draw cell guide
    doc.save();
    doc.rect(originX, originY, cellWidth, cellHeight).dash(1, { space: 3 }).strokeColor("#cccccc").stroke();

    const imageBuffer = await renderBarcode(label.barcode);
    const padding = 18;
    const imageWidth = cellWidth - padding * 2;
    const imageHeight = Math.min(cellHeight / 2.2, 80);
    const imageX = originX + (cellWidth - imageWidth) / 2;
    const imageY = originY + padding + 12;

    doc.fillColor("#000000").fontSize(11).text(label.name, originX + 8, originY + 8, {
      width: cellWidth - 16,
      align: "center",
    });

    doc.image(imageBuffer, imageX, imageY, {
      width: imageWidth,
      height: imageHeight,
    });

    doc.fontSize(10).text(label.barcode, originX + 8, originY + cellHeight - 28, {
      width: cellWidth - 16,
      align: "center",
    });

    doc.restore();
  }

  return new Promise((resolve) => {
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.end();
  });
}
