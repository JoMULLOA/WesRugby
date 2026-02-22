"use strict";
import PDFDocument from "pdfkit";

const normalizeText = (value = "") => {
  // Mantener caracteres especiales y acentos, asegurando UTF-8
  const text = value.toString().trim();
  // Normalizar caracteres Unicode a su forma canónica
  return text.normalize("NFC");
};

const formatDateTime = (raw) => {
  if (!raw) return "Sin fecha";
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return normalizeText(raw);
  return new Intl.DateTimeFormat("es-CL", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
};

const splitParticipantNames = (raw) => {
  if (!raw) return [];
  return raw
    .split(",")
    .map((name) => name.replace(/\s+/g, " ").trim())
    .filter((name) => name.length > 0)
    .sort((a, b) => a.localeCompare(b, "es", { sensitivity: "base" }));
};

export async function buildParticipacionesPdf({
  evento,
  estadisticasPorRama = [],
  filtros = [],
  totalGeneral = 0,
}) {
  const doc = new PDFDocument({
    size: "A4",
    margins: { top: 40, bottom: 48, left: 48, right: 48 },
    bufferPages: true,
    autoFirstPage: true,
    compress: false,
  });

  const chunks = [];
  doc.on("data", (chunk) => chunks.push(chunk));

  // Usar fuente Helvetica con codificación WinAnsi que soporta caracteres latinos
  doc.font("Helvetica");

  const renderHeader = () => {
    doc
      .fontSize(18)
      .fillColor("#111111")
      .text("Reporte de Participantes por Rama", { align: "left" })
      .moveDown(0.4);

    if (evento) {
      doc
        .fontSize(12)
        .fillColor("#333333")
        .text(`Evento: ${normalizeText(evento.nombre)}`);
      if (evento.fecha) {
        doc.text(`Fecha: ${formatDateTime(evento.fecha)}`);
      }
      if (evento.lugar) {
        doc.text(`Lugar: ${evento.lugar}`);
      }
      if (evento.tipo) {
        doc.text(`Tipo: ${evento.tipo}`);
      }
      doc.moveDown(0.4);
    }

    if (filtros.length > 0) {
      doc
        .fontSize(11)
        .fillColor("#444444")
        .text(`Categorías filtradas: ${filtros.join(", ")}`)
        .moveDown(0.3);
    }

    doc
      .fontSize(11)
      .fillColor("#222222")
      .text(`Total de niños participantes: ${totalGeneral}`)
      .moveDown(0.8);
  };

  renderHeader();

  if (!estadisticasPorRama.length) {
    doc
      .fontSize(12)
      .fillColor("#555555")
      .text(
        "No hay participaciones registradas con los criterios seleccionados.",
      );
  } else {
    const sortedRamas = [...estadisticasPorRama].sort((a, b) =>
      normalizeText(a.nombreRama).localeCompare(
        normalizeText(b.nombreRama),
        "es",
        {
          sensitivity: "base",
        },
      ),
    );

    for (const rama of sortedRamas) {
      doc
        .fontSize(14)
        .fillColor("#111111")
        .text(normalizeText(rama.nombreRama) || "Rama sin nombre", {
          underline: true,
        })
        .moveDown(0.1);

      doc
        .fontSize(11)
        .fillColor("#444444")
        .text(`Total de niños inscritos: ${rama.totalRama || 0}`)
        .moveDown(0.3);

      const categoriasMap = new Map();
      const participaciones = Array.isArray(rama.participaciones)
        ? rama.participaciones
        : [];

      for (const participacion of participaciones) {
        const categoria = normalizeText(
          participacion.categoria || "Sin categoría",
        );
        if (!categoriasMap.has(categoria)) {
          categoriasMap.set(categoria, {
            total: 0,
            participantes: [],
          });
        }
        const categoriaEntry = categoriasMap.get(categoria);
        const cantidad = Number(participacion.cantidadNinos) || 0;
        categoriaEntry.total += cantidad;
        categoriaEntry.participantes.push(
          ...splitParticipantNames(participacion.listaInvitados || ""),
        );
      }

      const categoriasOrdenadas = Array.from(categoriasMap.entries()).sort(
        (a, b) => a[0].localeCompare(b[0], "es", { sensitivity: "base" }),
      );

      if (categoriasOrdenadas.length === 0) {
        doc
          .fontSize(10)
          .fillColor("#666666")
          .text("Sin categorías registradas", { indent: 12 })
          .moveDown(0.6);
      } else {
        for (const [categoria, info] of categoriasOrdenadas) {
          doc
            .fontSize(12)
            .fillColor("#222222")
            .text(`• ${categoria.toUpperCase()} (${info.total} niños)`, {
              indent: 6,
            })
            .moveDown(0.1);

          const nombres = Array.from(new Set(info.participantes)).sort((a, b) =>
            a.localeCompare(b, "es", { sensitivity: "base" }),
          );

          if (nombres.length === 0) {
            doc
              .fontSize(10)
              .fillColor("#888888")
              .text("Sin nombres registrados", {
                indent: 22,
                width:
                  doc.page.width -
                  doc.page.margins.left -
                  doc.page.margins.right -
                  16,
              })
              .moveDown(0.3);
          } else {
            // Mostrar nombres numerados
            nombres.forEach((nombre, index) => {
              doc
                .fontSize(10)
                .fillColor("#444444")
                .text(`${index + 1}) ${nombre}`, {
                  indent: 22,
                  width:
                    doc.page.width -
                    doc.page.margins.left -
                    doc.page.margins.right -
                    16,
                });
            });
            doc.moveDown(0.3);
          }
        }
      }

      doc.moveDown(0.5);
    }
  }

  return new Promise((resolve) => {
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.end();
  });
}
