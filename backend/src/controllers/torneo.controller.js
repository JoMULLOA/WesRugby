"use strict";
import { AppDataSource } from "../config/configDb.js";
import Torneo from "../entity/torneo.entity.js";
import ParticipacionTorneo from "../entity/participacionTorneo.entity.js";
import User from "../entity/user.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

const torneoRepository = AppDataSource.getRepository(Torneo);
const participacionRepository = AppDataSource.getRepository(ParticipacionTorneo);
const userRepository = AppDataSource.getRepository(User);

// Crear nuevo torneo (solo directiva)
export const crearTorneo = async (req, res) => {
  try {
    console.log('🏆 CrearTorneo - Body received:', req.body);
    
    const { nombre, descripcion, fechaTorneo, lugar, categorias } = req.body;

    // Validar datos requeridos
    if (!nombre || !fechaTorneo || !categorias || !Array.isArray(categorias)) {
      return handleErrorClient(res, 400, "Datos incompletos: nombre, fechaTorneo y categorias son requeridos");
    }

    // Validar categorías permitidas
    const categoriasPermitidas = ["sub-8", "sub-10", "sub-12", "sub-14"];
    const categoriasInvalidas = categorias.filter(cat => !categoriasPermitidas.includes(cat));
    if (categoriasInvalidas.length > 0) {
      return handleErrorClient(res, 400, `Categorías inválidas: ${categoriasInvalidas.join(', ')}`);
    }

    // Crear el torneo
    const nuevoTorneo = torneoRepository.create({
      nombre: nombre.trim(),
      descripcion: descripcion?.trim() || null,
      fechaTorneo: new Date(fechaTorneo),
      lugar: lugar?.trim() || null,
      categorias: categorias,
      rutCreador: req.user.rut
    });

    const torneoGuardado = await torneoRepository.save(nuevoTorneo);

    console.log(`✅ Torneo creado por directiva ${req.user.rut}: ${torneoGuardado.nombre}`);

    handleSuccess(res, 201, "Torneo creado exitosamente", {
      id: torneoGuardado.id,
      nombre: torneoGuardado.nombre,
      descripcion: torneoGuardado.descripcion,
      fechaTorneo: torneoGuardado.fechaTorneo,
      lugar: torneoGuardado.lugar,
      categorias: torneoGuardado.categorias,
      estado: torneoGuardado.estado,
      createdAt: torneoGuardado.createdAt
    });

  } catch (error) {
    console.error("Error al crear torneo:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Obtener todos los torneos
export const obtenerTorneos = async (req, res) => {
  try {
    const { estado } = req.query;

    let whereCondition = {};
    if (estado && ['abierto', 'cerrado', 'finalizado', 'cancelado'].includes(estado)) {
      whereCondition.estado = estado;
    }

    const torneos = await torneoRepository.find({
      where: whereCondition,
      relations: ['creador', 'participaciones', 'participaciones.coordinador'],
      order: { fechaTorneo: 'DESC', createdAt: 'DESC' }
    });

    // Procesar los torneos para incluir estadísticas de participación
    const torneosConEstadisticas = torneos.map(torneo => {
      const participacionesPorCategoria = {};
      let totalNinos = 0;
      let totalInvitados = 0;

      torneo.participaciones.forEach(participacion => {
        if (!participacionesPorCategoria[participacion.categoria]) {
          participacionesPorCategoria[participacion.categoria] = {
            cantidad: 0,
            ninos: 0,
            invitados: 0,
            ramas: []
          };
        }
        
        participacionesPorCategoria[participacion.categoria].cantidad++;
        participacionesPorCategoria[participacion.categoria].ninos += participacion.cantidadNinos;
        participacionesPorCategoria[participacion.categoria].invitados += participacion.cantidadInvitados;
        participacionesPorCategoria[participacion.categoria].ramas.push({
          nombreRama: participacion.nombreRama,
          coordinador: participacion.coordinador.nombreCompleto
        });

        totalNinos += participacion.cantidadNinos;
        totalInvitados += participacion.cantidadInvitados;
      });

      return {
        id: torneo.id,
        nombre: torneo.nombre,
        descripcion: torneo.descripcion,
        fechaTorneo: torneo.fechaTorneo,
        lugar: torneo.lugar,
        categorias: torneo.categorias,
        estado: torneo.estado,
        creador: {
          rut: torneo.creador.rut,
          nombre: torneo.creador.nombreCompleto
        },
        estadisticas: {
          totalParticipaciones: torneo.participaciones.length,
          totalNinos,
          totalInvitados,
          participacionesPorCategoria
        },
        createdAt: torneo.createdAt,
        updatedAt: torneo.updatedAt
      };
    });

    handleSuccess(res, 200, "Torneos obtenidos exitosamente", torneosConEstadisticas);

  } catch (error) {
    console.error("Error al obtener torneos:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Obtener torneos disponibles para participar (coordinadores de rama)
export const obtenerTorneosDisponibles = async (req, res) => {
  try {
    const torneos = await torneoRepository.find({
      where: { estado: 'abierto' },
      relations: ['creador'],
      order: { fechaTorneo: 'ASC' }
    });

    const torneosDisponibles = torneos.map(torneo => ({
      id: torneo.id,
      nombre: torneo.nombre,
      descripcion: torneo.descripcion,
      fechaTorneo: torneo.fechaTorneo,
      lugar: torneo.lugar,
      categorias: torneo.categorias,
      creador: torneo.creador.nombreCompleto
    }));

    handleSuccess(res, 200, "Torneos disponibles obtenidos exitosamente", torneosDisponibles);

  } catch (error) {
    console.error("Error al obtener torneos disponibles:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Participar en torneo (coordinadores de rama)
export const participarEnTorneo = async (req, res) => {
  try {
    console.log('🏃 ParticiparEnTorneo - Body received:', req.body);
    
    const { 
      torneoId, 
      nombreRama, 
      categoria, 
      cantidadNinos, 
      cantidadInvitados, 
      detalleInvitados, 
      observaciones 
    } = req.body;

    // Validar datos requeridos
    if (!torneoId || !nombreRama || !categoria || cantidadNinos === undefined) {
      return handleErrorClient(res, 400, "Datos incompletos: torneoId, nombreRama, categoria y cantidadNinos son requeridos");
    }

    // Verificar que el torneo existe y está abierto
    const torneo = await torneoRepository.findOne({
      where: { id: torneoId }
    });

    if (!torneo) {
      return handleErrorClient(res, 404, "Torneo no encontrado");
    }

    if (torneo.estado !== 'abierto') {
      return handleErrorClient(res, 400, "El torneo no está disponible para participación");
    }

    // Verificar que la categoría está disponible en el torneo
    if (!torneo.categorias.includes(categoria)) {
      return handleErrorClient(res, 400, "La categoría seleccionada no está disponible en este torneo");
    }

    // Verificar si ya existe una participación del mismo coordinador en la misma categoría
    const participacionExistente = await participacionRepository.findOne({
      where: { 
        torneoId: torneoId, 
        rutCoordinador: req.user.rut, 
        categoria: categoria 
      }
    });

    if (participacionExistente) {
      return handleErrorClient(res, 400, "Ya tienes una participación registrada en esta categoría para este torneo");
    }

    // Crear la participación
    const nuevaParticipacion = participacionRepository.create({
      torneoId: torneoId,
      rutCoordinador: req.user.rut,
      nombreRama: nombreRama.trim(),
      categoria: categoria,
      cantidadNinos: parseInt(cantidadNinos) || 0,
      cantidadInvitados: parseInt(cantidadInvitados) || 0,
      detalleInvitados: detalleInvitados || null,
      observaciones: observaciones?.trim() || null
    });

    const participacionGuardada = await participacionRepository.save(nuevaParticipacion);

    console.log(`✅ Participación registrada: ${req.user.rut} en torneo ${torneoId}, categoría ${categoria}`);

    handleSuccess(res, 201, "Participación registrada exitosamente", {
      id: participacionGuardada.id,
      torneoId: participacionGuardada.torneoId,
      nombreRama: participacionGuardada.nombreRama,
      categoria: participacionGuardada.categoria,
      cantidadNinos: participacionGuardada.cantidadNinos,
      cantidadInvitados: participacionGuardada.cantidadInvitados,
      estado: participacionGuardada.estado,
      createdAt: participacionGuardada.createdAt
    });

  } catch (error) {
    console.error("Error al registrar participación:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Obtener participaciones del coordinador actual
export const obtenerMisParticipaciones = async (req, res) => {
  try {
    const participaciones = await participacionRepository.find({
      where: { rutCoordinador: req.user.rut },
      relations: ['torneo'],
      order: { createdAt: 'DESC' }
    });

    const participacionesFormateadas = participaciones.map(participacion => ({
      id: participacion.id,
      torneo: {
        id: participacion.torneo.id,
        nombre: participacion.torneo.nombre,
        fechaTorneo: participacion.torneo.fechaTorneo,
        lugar: participacion.torneo.lugar,
        estado: participacion.torneo.estado
      },
      nombreRama: participacion.nombreRama,
      categoria: participacion.categoria,
      cantidadNinos: participacion.cantidadNinos,
      cantidadInvitados: participacion.cantidadInvitados,
      detalleInvitados: participacion.detalleInvitados,
      observaciones: participacion.observaciones,
      estado: participacion.estado,
      createdAt: participacion.createdAt
    }));

    handleSuccess(res, 200, "Participaciones obtenidas exitosamente", participacionesFormateadas);

  } catch (error) {
    console.error("Error al obtener participaciones:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
};

// Actualizar estado del torneo (solo directiva)
export const actualizarEstadoTorneo = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!['abierto', 'cerrado', 'finalizado', 'cancelado'].includes(estado)) {
      return handleErrorClient(res, 400, "Estado inválido");
    }

    const torneo = await torneoRepository.findOne({ where: { id: parseInt(id) } });

    if (!torneo) {
      return handleErrorClient(res, 404, "Torneo no encontrado");
    }

    torneo.estado = estado;
    torneo.updatedAt = new Date();

    await torneoRepository.save(torneo);

    console.log(`✅ Estado del torneo ${id} actualizado a ${estado} por directiva ${req.user.rut}`);

    handleSuccess(res, 200, "Estado del torneo actualizado exitosamente", {
      id: torneo.id,
      nombre: torneo.nombre,
      estado: torneo.estado,
      updatedAt: torneo.updatedAt
    });

  } catch (error) {
    console.error("Error al actualizar estado del torneo:", error);
    handleErrorServer(res, 500, "Error interno del servidor");
  }
};