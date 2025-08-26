"use strict";
import VentaProducto from "../entity/ventaProducto.entity.js";
import Producto from "../entity/producto.entity.js";
import User from "../entity/user.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const ventaRepository = AppDataSource.getRepository(VentaProducto);
const productoRepository = AppDataSource.getRepository(Producto);
const userRepository = AppDataSource.getRepository(User);

// Crear venta de producto
export async function crearVentaProducto(req, res) {
  try {
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const {
      rutComprador,
      productos, // Array de { productoId, cantidad, precioUnitario }
      metodoPago,
      observaciones,
      descuentoAplicado = 0
    } = req.body;

    // Verificar autorización
    if (userRole === "apoderado") {
      // Apoderados solo pueden comprar para ellos o sus hijos
      if (rutComprador !== userRut) {
        const hijo = await userRepository.findOne({
          where: { rut: rutComprador, rutApoderado: userRut }
        });
        if (!hijo) {
          return handleErrorClient(res, 403, "No autorizado", 
            "Solo puede comprar para usted o sus hijos");
        }
      }
    } else if (!["tesorera", "directiva", "entrenador"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    // Verificar que el comprador existe
    const comprador = await userRepository.findOneBy({ rut: rutComprador });
    if (!comprador) {
      return handleErrorClient(res, 404, "Comprador no encontrado");
    }

    if (!productos || productos.length === 0) {
      return handleErrorClient(res, 400, "Productos requeridos", 
        "Debe seleccionar al menos un producto");
    }

    // Validar productos y stock
    let subtotal = 0;
    const productosValidados = [];

    for (const item of productos) {
      const producto = await productoRepository.findOne({
        where: { id: item.productoId, activo: true }
      });

      if (!producto) {
        return handleErrorClient(res, 404, 
          `Producto con ID ${item.productoId} no encontrado o inactivo`);
      }

      if (producto.stock < item.cantidad) {
        return handleErrorClient(res, 400, "Stock insuficiente", 
          `No hay suficiente stock del producto ${producto.nombre}. Disponible: ${producto.stock}`);
      }

      const precioUnitario = item.precioUnitario || producto.precio;
      const totalProducto = precioUnitario * item.cantidad;
      subtotal += totalProducto;

      productosValidados.push({
        producto,
        cantidad: item.cantidad,
        precioUnitario,
        total: totalProducto
      });
    }

    // Calcular totales
    const descuento = (subtotal * descuentoAplicado) / 100;
    const total = subtotal - descuento;

    // Generar código de venta único
    const fechaActual = new Date();
    const codigoVenta = `V${fechaActual.getFullYear()}${(fechaActual.getMonth() + 1).toString().padStart(2, '0')}${fechaActual.getDate().toString().padStart(2, '0')}-${Date.now().toString().slice(-6)}`;

    // Crear la venta
    const nuevaVenta = ventaRepository.create({
      codigoVenta,
      rutComprador,
      productos: productosValidados.map(p => ({
        productoId: p.producto.id,
        nombreProducto: p.producto.nombre,
        categoria: p.producto.categoria,
        talla: p.producto.talla,
        color: p.producto.color,
        cantidad: p.cantidad,
        precioUnitario: p.precioUnitario,
        total: p.total
      })),
      subtotal,
      descuentoAplicado,
      descuento,
      total,
      metodoPago,
      observaciones,
      vendidoPorRut: req.user.rut,
      estado: "completada"
    });

    const ventaGuardada = await ventaRepository.save(nuevaVenta);

    // Actualizar stock de productos
    for (const item of productosValidados) {
      item.producto.stock -= item.cantidad;
      await productoRepository.save(item.producto);
    }

    const ventaCompleta = await ventaRepository.findOne({
      where: { id: ventaGuardada.id },
      relations: ["comprador", "vendidoPor"]
    });

    handleSuccess(res, 201, "Venta registrada exitosamente", ventaCompleta);

  } catch (error) {
    console.error("Error creando venta:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener ventas
export async function obtenerVentas(req, res) {
  try {
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const {
      fechaInicio,
      fechaFin,
      rutComprador,
      metodoPago,
      estado,
      limite = 50,
      pagina = 1
    } = req.query;

    let whereCondition = {};

    // Filtros por rol
    if (userRole === "apoderado") {
      // Apoderados solo ven sus compras y de sus hijos
      const hijos = await userRepository.find({
        where: { rutApoderado: userRut }
      });
      
      const rutsPermitidos = [userRut, ...hijos.map(hijo => hijo.rut)];
      whereCondition.rutComprador = { $in: rutsPermitidos };
    } else if (rutComprador) {
      whereCondition.rutComprador = rutComprador;
    }

    // Aplicar filtros
    if (fechaInicio && fechaFin) {
      whereCondition.createdAt = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    if (metodoPago) {
      whereCondition.metodoPago = metodoPago;
    }

    if (estado) {
      whereCondition.estado = estado;
    }

    const skip = (parseInt(pagina) - 1) * parseInt(limite);

    const [ventas, total] = await ventaRepository.findAndCount({
      where: whereCondition,
      relations: ["comprador", "vendidoPor"],
      order: { createdAt: "DESC" },
      take: parseInt(limite),
      skip: skip
    });

    const resultado = {
      ventas,
      paginacion: {
        total,
        pagina: parseInt(pagina),
        limite: parseInt(limite),
        totalPaginas: Math.ceil(total / parseInt(limite))
      }
    };

    handleSuccess(res, 200, "Ventas obtenidas exitosamente", resultado);

  } catch (error) {
    console.error("Error obteniendo ventas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener venta por ID
export async function obtenerVentaPorId(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;
    const userRut = req.user.rut;

    const venta = await ventaRepository.findOne({
      where: { id },
      relations: ["comprador", "vendidoPor"]
    });

    if (!venta) {
      return handleErrorClient(res, 404, "Venta no encontrada");
    }

    // Verificar autorización para apoderados
    if (userRole === "apoderado") {
      const puedeVer = venta.rutComprador === userRut;
      
      if (!puedeVer) {
        const hijo = await userRepository.findOne({
          where: { rut: venta.rutComprador, rutApoderado: userRut }
        });
        if (!hijo) {
          return handleErrorClient(res, 403, "No autorizado");
        }
      }
    }

    handleSuccess(res, 200, "Venta obtenida exitosamente", venta);

  } catch (error) {
    console.error("Error obteniendo venta:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Anular venta (Directiva, Tesorera)
export async function anularVenta(req, res) {
  try {
    const { id } = req.params;
    const { motivo } = req.body;
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y tesorera pueden anular ventas");
    }

    const venta = await ventaRepository.findOneBy({ id });
    if (!venta) {
      return handleErrorClient(res, 404, "Venta no encontrada");
    }

    if (venta.estado === "anulada") {
      return handleErrorClient(res, 400, "Venta ya anulada");
    }

    // Restaurar stock de productos
    for (const item of venta.productos) {
      const producto = await productoRepository.findOneBy({ 
        id: item.productoId 
      });
      if (producto) {
        producto.stock += item.cantidad;
        await productoRepository.save(producto);
      }
    }

    venta.estado = "anulada";
    venta.fechaAnulacion = new Date();
    venta.motivoAnulacion = motivo;
    venta.anuladoPorRut = req.user.rut;

    const ventaAnulada = await ventaRepository.save(venta);

    const ventaCompleta = await ventaRepository.findOne({
      where: { id: ventaAnulada.id },
      relations: ["comprador", "vendidoPor", "anuladoPor"]
    });

    handleSuccess(res, 200, "Venta anulada exitosamente", ventaCompleta);

  } catch (error) {
    console.error("Error anulando venta:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estadísticas de ventas
export async function obtenerEstadisticasVentas(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { fechaInicio, fechaFin } = req.query;

    let whereCondition = { estado: "completada" };

    if (fechaInicio && fechaFin) {
      whereCondition.createdAt = {
        $gte: fechaInicio,
        $lte: fechaFin
      };
    }

    // Total de ventas
    const totalVentas = await ventaRepository.count({ where: whereCondition });

    // Ingresos totales
    const ingresosTotales = await ventaRepository
      .createQueryBuilder("venta")
      .select("SUM(venta.total)", "total")
      .where("venta.estado = :estado", { estado: "completada" })
      .andWhere(whereCondition.createdAt ? 
        "venta.createdAt BETWEEN :fechaInicio AND :fechaFin" : "1=1", 
        { fechaInicio, fechaFin })
      .getRawOne();

    // Ventas por método de pago
    const porMetodoPago = await ventaRepository
      .createQueryBuilder("venta")
      .select("venta.metodoPago", "metodo")
      .addSelect("COUNT(*)", "cantidad")
      .addSelect("SUM(venta.total)", "total")
      .where("venta.estado = :estado", { estado: "completada" })
      .groupBy("venta.metodoPago")
      .getRawMany();

    // Productos más vendidos
    const productosMasVendidos = await ventaRepository
      .createQueryBuilder("venta")
      .select("productos->>'$.nombreProducto'", "producto")
      .addSelect("productos->>'$.categoria'", "categoria")
      .addSelect("SUM(CAST(productos->>'$.cantidad' AS UNSIGNED))", "cantidadVendida")
      .addSelect("SUM(CAST(productos->>'$.total' AS DECIMAL(10,2)))", "ingresoTotal")
      .where("venta.estado = :estado", { estado: "completada" })
      .groupBy("producto", "categoria")
      .orderBy("cantidadVendida", "DESC")
      .limit(10)
      .getRawMany();

    // Ventas por mes (últimos 12 meses)
    const ventasMensuales = await ventaRepository
      .createQueryBuilder("venta")
      .select("DATE_FORMAT(venta.createdAt, '%Y-%m')", "mes")
      .addSelect("COUNT(*)", "cantidad")
      .addSelect("SUM(venta.total)", "ingresos")
      .where("venta.estado = :estado", { estado: "completada" })
      .andWhere("venta.createdAt >= DATE_SUB(NOW(), INTERVAL 12 MONTH)")
      .groupBy("mes")
      .orderBy("mes", "DESC")
      .getRawMany();

    // Compradores más frecuentes
    const compradoresFrecuentes = await ventaRepository
      .createQueryBuilder("venta")
      .leftJoinAndSelect("venta.comprador", "comprador")
      .select("comprador.nombres", "nombres")
      .addSelect("comprador.apellidos", "apellidos")
      .addSelect("COUNT(*)", "totalCompras")
      .addSelect("SUM(venta.total)", "totalGastado")
      .where("venta.estado = :estado", { estado: "completada" })
      .groupBy("venta.rutComprador")
      .orderBy("totalCompras", "DESC")
      .limit(10)
      .getRawMany();

    const estadisticas = {
      resumen: {
        totalVentas,
        ingresosTotales: ingresosTotales?.total || 0,
        ventaPromedio: totalVentas > 0 ? (ingresosTotales?.total || 0) / totalVentas : 0
      },
      distribucion: {
        porMetodoPago
      },
      productos: {
        masVendidos: productosMasVendidos
      },
      tendencias: {
        ventasMensuales
      },
      clientes: {
        compradoresFrecuentes
      }
    };

    handleSuccess(res, 200, "Estadísticas de ventas obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Calcular total de venta (utilidad para frontend)
export async function calcularTotalVenta(req, res) {
  try {
    const { productos, descuentoAplicado = 0 } = req.body;

    if (!productos || productos.length === 0) {
      return handleErrorClient(res, 400, "Productos requeridos");
    }

    let subtotal = 0;
    const productosCalculados = [];

    for (const item of productos) {
      const producto = await productoRepository.findOne({
        where: { id: item.productoId, activo: true }
      });

      if (!producto) {
        return handleErrorClient(res, 404, 
          `Producto con ID ${item.productoId} no encontrado`);
      }

      if (producto.stock < item.cantidad) {
        return handleErrorClient(res, 400, "Stock insuficiente", 
          `No hay suficiente stock del producto ${producto.nombre}`);
      }

      const precioUnitario = item.precioUnitario || producto.precio;
      const totalProducto = precioUnitario * item.cantidad;
      subtotal += totalProducto;

      productosCalculados.push({
        productoId: producto.id,
        nombre: producto.nombre,
        cantidad: item.cantidad,
        precioUnitario,
        total: totalProducto
      });
    }

    const descuento = (subtotal * descuentoAplicado) / 100;
    const total = subtotal - descuento;

    const calculo = {
      productos: productosCalculados,
      subtotal,
      descuentoAplicado,
      descuento,
      total
    };

    handleSuccess(res, 200, "Total calculado exitosamente", calculo);

  } catch (error) {
    console.error("Error calculando total:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener reporte de ventas por período
export async function obtenerReporteVentas(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const { fechaInicio, fechaFin, formato = "resumen" } = req.query;

    if (!fechaInicio || !fechaFin) {
      return handleErrorClient(res, 400, "Fechas requeridas", 
        "Debe especificar fecha de inicio y fin");
    }

    const whereCondition = {
      estado: "completada",
      createdAt: {
        $gte: fechaInicio,
        $lte: fechaFin
      }
    };

    const ventas = await ventaRepository.find({
      where: whereCondition,
      relations: ["comprador", "vendidoPor"],
      order: { createdAt: "DESC" }
    });

    let reporte = {
      periodo: { fechaInicio, fechaFin },
      totalVentas: ventas.length,
      ingresoTotal: ventas.reduce((sum, v) => sum + v.total, 0)
    };

    if (formato === "detallado") {
      reporte.ventas = ventas;
    }

    handleSuccess(res, 200, "Reporte de ventas generado exitosamente", reporte);

  } catch (error) {
    console.error("Error generando reporte:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
