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
    doc.rect(originX, originY, cellWidth, cellHeight).dash(1, { space: 3 }).strokeColor("#dddddd").stroke();

    const imageBuffer = await renderBarcode(label.barcode);
    const horizontalPadding = 24;
    const nameTop = originY + 10;
    const barcodeTop = originY + 44;
    const imageWidth = cellWidth - horizontalPadding * 2;
    const imageHeight = Math.min(cellHeight / 2.6, 72);
    const imageX = originX + (cellWidth - imageWidth) / 2;

    doc.fillColor("#000000").fontSize(11).text(label.name, originX + horizontalPadding / 2, nameTop, {
      width: cellWidth - horizontalPadding,
      align: "center",
    });

    doc.image(imageBuffer, imageX, barcodeTop, {
      width: imageWidth,
      height: imageHeight,
    });

    const codeY = barcodeTop + imageHeight + 14;
    doc.fontSize(11).text(label.barcode, originX + horizontalPadding / 2, codeY, {
      width: cellWidth - horizontalPadding,
      align: "center",
    });

    doc.restore();
  }

  return new Promise((resolve) => {
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.end();
  });
}
