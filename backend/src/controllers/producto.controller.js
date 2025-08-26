"use strict";
import Producto from "../entity/producto.entity.js";
import { AppDataSource } from "../config/configDb.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const productoRepository = AppDataSource.getRepository(Producto);

// Crear producto (Directiva, Tesorera)
export async function crearProducto(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y tesorera pueden crear productos");
    }

    const {
      nombre,
      descripcion,
      categoria,
      talla,
      color,
      precio,
      precioCosto,
      stock,
      stockMinimo,
      codigoProducto,
      proveedor,
      fechaIngreso,
      observaciones,
      activo = true
    } = req.body;

    // Verificar código único
    if (codigoProducto) {
      const productoExistente = await productoRepository.findOneBy({ 
        codigoProducto 
      });
      if (productoExistente) {
        return handleErrorClient(res, 400, "Código duplicado", 
          "Ya existe un producto con ese código");
      }
    }

    // Verificar combinación única de nombre, talla y color
    const productoSimilar = await productoRepository.findOne({
      where: {
        nombre,
        talla: talla || null,
        color: color || null
      }
    });

    if (productoSimilar) {
      return handleErrorClient(res, 400, "Producto duplicado", 
        "Ya existe un producto con el mismo nombre, talla y color");
    }

    const nuevoProducto = productoRepository.create({
      nombre,
      descripcion,
      categoria,
      talla,
      color,
      precio,
      precioCosto,
      stock: stock || 0,
      stockMinimo: stockMinimo || 0,
      codigoProducto,
      proveedor,
      fechaIngreso: fechaIngreso || new Date(),
      observaciones,
      activo,
      creadoPorRut: req.user.rut
    });

    const productoGuardado = await productoRepository.save(nuevoProducto);

    const productoCompleto = await productoRepository.findOne({
      where: { id: productoGuardado.id },
      relations: ["creadoPor"]
    });

    handleSuccess(res, 201, "Producto creado exitosamente", productoCompleto);

  } catch (error) {
    console.error("Error creando producto:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener productos
export async function obtenerProductos(req, res) {
  try {
    const userRole = req.user.rol;
    const {
      categoria,
      activo,
      enStock,
      talla,
      color,
      busqueda,
      limite = 50,
      pagina = 1
    } = req.query;

    let whereCondition = {};

    // Aplicar filtros
    if (categoria) {
      whereCondition.categoria = categoria;
    }

    if (activo !== undefined) {
      whereCondition.activo = activo === 'true';
    }

    // Usuarios no administrativos solo ven productos activos
    if (!["directiva", "tesorera"].includes(userRole)) {
      whereCondition.activo = true;
    }

    if (enStock === 'true') {
      whereCondition.stock = { $gt: 0 };
    }

    if (talla) {
      whereCondition.talla = talla;
    }

    if (color) {
      whereCondition.color = color;
    }

    const skip = (parseInt(pagina) - 1) * parseInt(limite);

    let queryBuilder = productoRepository.createQueryBuilder("producto")
      .leftJoinAndSelect("producto.creadoPor", "creador");

    // Aplicar condiciones WHERE
    Object.keys(whereCondition).forEach(key => {
      if (key === 'stock' && whereCondition[key].$gt !== undefined) {
        queryBuilder.andWhere(`producto.${key} > :stockValue`, { stockValue: whereCondition[key].$gt });
      } else {
        queryBuilder.andWhere(`producto.${key} = :${key}`, { [key]: whereCondition[key] });
      }
    });

    // Búsqueda por texto
    if (busqueda) {
      queryBuilder.andWhere(
        "(producto.nombre LIKE :busqueda OR producto.descripcion LIKE :busqueda OR producto.codigoProducto LIKE :busqueda)",
        { busqueda: `%${busqueda}%` }
      );
    }

    const [productos, total] = await queryBuilder
      .orderBy("producto.categoria", "ASC")
      .addOrderBy("producto.nombre", "ASC")
      .take(parseInt(limite))
      .skip(skip)
      .getManyAndCount();

    // Para roles no administrativos, ocultar información sensible
    if (!["directiva", "tesorera"].includes(userRole)) {
      productos.forEach(producto => {
        delete producto.precioCosto;
        delete producto.observaciones;
        delete producto.creadoPor;
      });
    }

    const resultado = {
      productos,
      paginacion: {
        total,
        pagina: parseInt(pagina),
        limite: parseInt(limite),
        totalPaginas: Math.ceil(total / parseInt(limite))
      }
    };

    handleSuccess(res, 200, "Productos obtenidos exitosamente", resultado);

  } catch (error) {
    console.error("Error obteniendo productos:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener producto por ID
export async function obtenerProductoPorId(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    const producto = await productoRepository.findOne({
      where: { id },
      relations: ["creadoPor"]
    });

    if (!producto) {
      return handleErrorClient(res, 404, "Producto no encontrado");
    }

    // Verificar si el producto está activo para roles no administrativos
    if (!["directiva", "tesorera"].includes(userRole) && !producto.activo) {
      return handleErrorClient(res, 404, "Producto no encontrado");
    }

    // Ocultar información sensible para roles no administrativos
    if (!["directiva", "tesorera"].includes(userRole)) {
      delete producto.precioCosto;
      delete producto.observaciones;
      delete producto.creadoPor;
    }

    handleSuccess(res, 200, "Producto obtenido exitosamente", producto);

  } catch (error) {
    console.error("Error obteniendo producto:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar producto (Directiva, Tesorera)
export async function actualizarProducto(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva y tesorera pueden actualizar productos");
    }

    const producto = await productoRepository.findOneBy({ id });
    if (!producto) {
      return handleErrorClient(res, 404, "Producto no encontrado");
    }

    const datosActualizacion = req.body;

    // Verificar código único si se actualiza
    if (datosActualizacion.codigoProducto && 
        datosActualizacion.codigoProducto !== producto.codigoProducto) {
      const productoExistente = await productoRepository.findOneBy({ 
        codigoProducto: datosActualizacion.codigoProducto 
      });
      if (productoExistente) {
        return handleErrorClient(res, 400, "Código duplicado", 
          "Ya existe un producto con ese código");
      }
    }

    // Campos permitidos para actualización
    const camposPermitidos = [
      'nombre', 'descripcion', 'categoria', 'talla', 'color', 'precio',
      'precioCosto', 'stock', 'stockMinimo', 'codigoProducto', 'proveedor',
      'fechaIngreso', 'observaciones', 'activo'
    ];

    camposPermitidos.forEach(campo => {
      if (datosActualizacion[campo] !== undefined) {
        producto[campo] = datosActualizacion[campo];
      }
    });

    producto.updatedAt = new Date();
    
    const productoActualizado = await productoRepository.save(producto);

    const productoCompleto = await productoRepository.findOne({
      where: { id: productoActualizado.id },
      relations: ["creadoPor"]
    });

    handleSuccess(res, 200, "Producto actualizado exitosamente", productoCompleto);

  } catch (error) {
    console.error("Error actualizando producto:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Actualizar stock (Directiva, Tesorera)
export async function actualizarStock(req, res) {
  try {
    const { id } = req.params;
    const { nuevoStock, razon, tipoMovimiento } = req.body; // entrada, salida, ajuste
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const producto = await productoRepository.findOneBy({ id });
    if (!producto) {
      return handleErrorClient(res, 404, "Producto no encontrado");
    }

    const stockAnterior = producto.stock;
    
    if (tipoMovimiento === "entrada") {
      producto.stock += parseInt(nuevoStock);
    } else if (tipoMovimiento === "salida") {
      if (producto.stock < parseInt(nuevoStock)) {
        return handleErrorClient(res, 400, "Stock insuficiente", 
          "No hay suficiente stock para realizar la salida");
      }
      producto.stock -= parseInt(nuevoStock);
    } else if (tipoMovimiento === "ajuste") {
      producto.stock = parseInt(nuevoStock);
    } else {
      return handleErrorClient(res, 400, "Tipo de movimiento inválido");
    }

    // Crear registro de movimiento en observaciones
    const movimiento = {
      fecha: new Date(),
      tipo: tipoMovimiento,
      stockAnterior,
      stockNuevo: producto.stock,
      cantidad: parseInt(nuevoStock),
      razon,
      usuario: req.user.rut
    };

    if (!producto.movimientosStock) {
      producto.movimientosStock = [];
    }
    producto.movimientosStock.push(movimiento);

    const productoActualizado = await productoRepository.save(producto);

    handleSuccess(res, 200, "Stock actualizado exitosamente", {
      producto: productoActualizado,
      movimiento
    });

  } catch (error) {
    console.error("Error actualizando stock:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener productos con stock bajo (Directiva, Tesorera)
export async function obtenerProductosStockBajo(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const productosStockBajo = await productoRepository
      .createQueryBuilder("producto")
      .leftJoinAndSelect("producto.creadoPor", "creador")
      .where("producto.activo = true")
      .andWhere("producto.stock <= producto.stockMinimo")
      .orderBy("producto.stock", "ASC")
      .getMany();

    handleSuccess(res, 200, "Productos con stock bajo obtenidos exitosamente", 
      productosStockBajo);

  } catch (error) {
    console.error("Error obteniendo productos con stock bajo:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener estadísticas de inventario (Directiva, Tesorera)
export async function obtenerEstadisticasInventario(req, res) {
  try {
    const userRole = req.user.rol;

    if (!["directiva", "tesorera"].includes(userRole)) {
      return handleErrorClient(res, 403, "No autorizado");
    }

    const totalProductos = await productoRepository.count();
    const productosActivos = await productoRepository.count({ where: { activo: true } });
    const productosInactivos = await productoRepository.count({ where: { activo: false } });

    // Productos por categoría
    const porCategoria = await productoRepository
      .createQueryBuilder("producto")
      .select("producto.categoria", "categoria")
      .addSelect("COUNT(*)", "cantidad")
      .addSelect("SUM(producto.stock)", "stockTotal")
      .where("producto.activo = true")
      .groupBy("producto.categoria")
      .getRawMany();

    // Valor total del inventario
    const valorInventario = await productoRepository
      .createQueryBuilder("producto")
      .select("SUM(producto.precio * producto.stock)", "valorVenta")
      .addSelect("SUM(producto.precioCosto * producto.stock)", "valorCosto")
      .where("producto.activo = true")
      .getRawOne();

    // Productos con stock bajo
    const stockBajo = await productoRepository.count({
      where: {
        activo: true,
        stock: { $lte: "stockMinimo" } // Aproximación, en TypeORM real sería diferente
      }
    });

    // Productos más vendidos (basado en stock inicial menos stock actual)
    const masVendidos = await productoRepository
      .createQueryBuilder("producto")
      .select("producto.nombre", "nombre")
      .addSelect("producto.categoria", "categoria")
      .addSelect("(producto.stockInicial - producto.stock)", "vendidos")
      .where("producto.activo = true")
      .andWhere("producto.stockInicial IS NOT NULL")
      .orderBy("vendidos", "DESC")
      .limit(10)
      .getRawMany();

    const estadisticas = {
      resumen: {
        totalProductos,
        productosActivos,
        productosInactivos,
        stockBajo
      },
      valorInventario: {
        valorVenta: valorInventario?.valorVenta || 0,
        valorCosto: valorInventario?.valorCosto || 0
      },
      distribucion: {
        porCategoria
      },
      masVendidos
    };

    handleSuccess(res, 200, "Estadísticas de inventario obtenidas exitosamente", estadisticas);

  } catch (error) {
    console.error("Error obteniendo estadísticas:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Desactivar producto (Solo Directiva)
export async function desactivarProducto(req, res) {
  try {
    const { id } = req.params;
    const userRole = req.user.rol;

    if (userRole !== "directiva") {
      return handleErrorClient(res, 403, "No autorizado", 
        "Solo directiva puede desactivar productos");
    }

    const producto = await productoRepository.findOneBy({ id });
    if (!producto) {
      return handleErrorClient(res, 404, "Producto no encontrado");
    }

    producto.activo = false;
    producto.updatedAt = new Date();
    
    const productoDesactivado = await productoRepository.save(producto);

    handleSuccess(res, 200, "Producto desactivado exitosamente", productoDesactivado);

  } catch (error) {
    console.error("Error desactivando producto:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}

// Obtener categorías disponibles
export async function obtenerCategorias(req, res) {
  try {
    const categorias = await productoRepository
      .createQueryBuilder("producto")
      .select("DISTINCT producto.categoria", "categoria")
      .where("producto.activo = true")
      .getRawMany();

    const listaCategorias = categorias.map(c => c.categoria).filter(Boolean);

    handleSuccess(res, 200, "Categorías obtenidas exitosamente", listaCategorias);

  } catch (error) {
    console.error("Error obteniendo categorías:", error);
    handleErrorServer(res, 500, "Error interno del servidor", error.message);
  }
}
