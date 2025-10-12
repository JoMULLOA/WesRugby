"use strict";
import { AppDataSource } from "../config/configDb.js";
import Evento from "../entity/evento.entity.js";
import ParticipacionEvento from "../entity/participacionEvento.entity.js";
import User from "../entity/user.entity.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

// Crear un nuevo evento (solo directiva)
export async function crearEvento(req, res) {
  try {
    const { nombre, fecha, descripcion } = req.body;

    if (!nombre || !fecha) {
      return handleErrorClient(
        res,
        400,
        "Faltan campos obligatorios",
        "Nombre y fecha son requeridos"
      );
    }

    const eventoRepository = AppDataSource.getRepository(Evento);

    // Validación para prevenir eventos duplicados
    const eventoExistente = await eventoRepository.findOne({
      where: {
        nombre,
        fecha: new Date(fecha),
        estado: "activo"
      }
    });

    if (eventoExistente) {
      return handleErrorClient(
        res,
        400,
        "Evento duplicado",
        "Ya existe un evento activo con el mismo nombre y fecha. Por favor, modifica alguno de estos campos."
      );
    }

    const nuevoEvento = eventoRepository.create({
      nombre,
      fecha: new Date(fecha),
      descripcion: descripcion || null,
      estado: "activo",
    });

    const eventoGuardado = await eventoRepository.save(nuevoEvento);

    handleSuccess(res, 201, "Evento creado exitosamente", eventoGuardado);
  } catch (error) {
    console.error("Error al crear evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener todos los eventos (directiva)
export async function obtenerEventos(req, res) {
  try {
    const eventoRepository = AppDataSource.getRepository(Evento);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);

    const eventos = await eventoRepository.find({
      order: { createdAt: "DESC" },
    });

    // Agregar conteo de participaciones a cada evento
    const eventosConParticipaciones = await Promise.all(
      eventos.map(async (evento) => {
        const participaciones = await participacionRepository.count({
          where: { eventoId: evento.id }
        });
        return {
          ...evento,
          totalParticipaciones: participaciones
        };
      })
    );

    handleSuccess(res, 200, "Eventos obtenidos exitosamente", eventosConParticipaciones);
  } catch (error) {
    console.error("Error al obtener eventos:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener eventos disponibles para participación (RamaExterna)
export async function obtenerEventosDisponibles(req, res) {
  try {
    const eventoRepository = AppDataSource.getRepository(Evento);
    
    // Importar el repositorio de eventos deportivos
    const { AppDataSource: dataSource } = await import("../config/configDb.js");
    const EventoDeportivo = (await import("../entity/eventoDeportivo.entity.js")).default;
    const eventoDeportivoRepository = dataSource.getRepository(EventoDeportivo);

    const fechaActual = new Date();

    // Los eventos regulares (como reuniones de directiva) NO están disponibles para participación de rama externa
    // Solo los eventos deportivos pueden tener participación de ramas externas
    const eventosRegularesActivos = [];

    // Obtener eventos deportivos activos y convertirlos al formato esperado
    const eventosDeportivos = await eventoDeportivoRepository.find({
      where: { estado: "programado" },
      relations: ["organizadoPor"],
      order: { fechaInicio: "ASC" },
    });

    // Filtrar y convertir eventos deportivos que no hayan pasado
    const eventosDeportivosFormateados = eventosDeportivos
      .filter(eventoDeportivo => {
        const fechaEvento = new Date(eventoDeportivo.fechaInicio);
        return fechaEvento >= fechaActual;
      })
      .map(eventoDeportivo => ({
        id: eventoDeportivo.id,
        nombre: eventoDeportivo.titulo,
        fecha: eventoDeportivo.fechaInicio,
        fechaFin: eventoDeportivo.fechaFin,
        horaInicio: eventoDeportivo.horaInicio,
        horaFin: eventoDeportivo.horaFin,
        descripcion: eventoDeportivo.descripcion,
        estado: "activo",
        lugar: eventoDeportivo.lugar,
        categoria: eventoDeportivo.categoria,
        tipoEvento: eventoDeportivo.tipoEvento,
        // Marcar como evento deportivo para distinguirlo
        esEventoDeportivo: true,
        createdAt: eventoDeportivo.createdAt,
        updatedAt: eventoDeportivo.updatedAt
      }));

    // Combinar ambos tipos de eventos (solo los que no han pasado)
    const todosLosEventos = [...eventosRegularesActivos, ...eventosDeportivosFormateados];
    
    // Ordenar por fecha
    todosLosEventos.sort((a, b) => new Date(a.fecha) - new Date(b.fecha));

    handleSuccess(res, 200, "Eventos disponibles obtenidos exitosamente", todosLosEventos);
  } catch (error) {
    console.error("Error al obtener eventos disponibles:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Editar participación en un evento (RamaExterna - solo durante 10 minutos)
export async function editarParticipacion(req, res) {
  try {
    const { participacionId } = req.params;
    const { cantidadNinos, listaInvitados } = req.body;
    const rutRamaExterna = req.user.rut;

    if (!cantidadNinos) {
      return handleErrorClient(
        res,
        400,
        "Faltan campos obligatorios",
        "La cantidad de niños es requerida"
      );
    }

    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);
    
    // Importar repositorios para eventos deportivos
    const { AppDataSource: dataSource } = await import("../config/configDb.js");
    const ParticipacionEventoDeportivo = (await import("../entity/participacionEventoDeportivo.entity.js")).default;
    const participacionDeportivaRepository = dataSource.getRepository(ParticipacionEventoDeportivo);

    // Buscar la participación (puede ser regular o deportiva)
    let participacion = await participacionRepository.findOne({
      where: { id: parseInt(participacionId), rutRamaExterna }
    });
    
    let esEventoDeportivo = false;
    if (!participacion) {
      participacion = await participacionDeportivaRepository.findOne({
        where: { id: parseInt(participacionId), rutRamaExterna }
      });
      esEventoDeportivo = true;
    }

    if (!participacion) {
      return handleErrorClient(
        res,
        404,
        "Error al editar",
        "Participación no encontrada o no tienes permisos para editarla"
      );
    }

    // Verificar que no hayan pasado más de 10 minutos
    const tiempoLimite = 10 * 60 * 1000; // 10 minutos en milisegundos
    const tiempoTranscurrido = Date.now() - new Date(participacion.createdAt).getTime();
    
    if (tiempoTranscurrido > tiempoLimite) {
      return handleErrorClient(
        res,
        400,
        "Tiempo agotado",
        "Solo puedes editar una participación durante los primeros 10 minutos después de crearla"
      );
    }

    // Actualizar los campos permitidos
    participacion.cantidadNinos = cantidadNinos;
    if (listaInvitados !== undefined) {
      participacion.listaInvitados = listaInvitados;
    }

    let participacionActualizada;
    if (esEventoDeportivo) {
      participacionActualizada = await participacionDeportivaRepository.save(participacion);
    } else {
      participacionActualizada = await participacionRepository.save(participacion);
    }

    handleSuccess(res, 200, "Participación actualizada exitosamente", participacionActualizada);
  } catch (error) {
    console.error("Error al editar participación:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Participar en un evento (RamaExterna)
export async function participarEnEvento(req, res) {
  try {
    const { eventoId, cantidadNinos, categoria, listaInvitados } = req.body;
    const rutRamaExterna = req.user.rut;

    if (!eventoId || !cantidadNinos || !categoria) {
      return handleErrorClient(
        res,
        400,
        "Faltan campos obligatorios",
        "ID del evento, cantidad de niños y categoría son requeridos"
      );
    }

    const eventoRepository = AppDataSource.getRepository(Evento);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);

    // Importar el repositorio de eventos deportivos y participaciones deportivas
    const { AppDataSource: dataSource } = await import("../config/configDb.js");
    const EventoDeportivo = (await import("../entity/eventoDeportivo.entity.js")).default;
    const ParticipacionEventoDeportivo = (await import("../entity/participacionEventoDeportivo.entity.js")).default;
    const eventoDeportivoRepository = dataSource.getRepository(EventoDeportivo);
    const participacionDeportivaRepository = dataSource.getRepository(ParticipacionEventoDeportivo);

    // Función para verificar si es un UUID válido
    const esUUID = (str) => {
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      return uuidRegex.test(str);
    };

    let evento = null;

    // Determinar el tipo de ID y buscar en la tabla correspondiente
    if (esUUID(eventoId)) {
      // Es un UUID, buscar en eventos deportivos
      const eventoDeportivo = await eventoDeportivoRepository.findOne({
        where: { id: eventoId }
      });
      
      if (eventoDeportivo && (eventoDeportivo.estado === "programado" || eventoDeportivo.estado === "activo")) {
        // Usar el evento deportivo como si fuera un evento regular
        evento = {
          id: eventoDeportivo.id,
          nombre: eventoDeportivo.titulo,  
          estado: "activo",
          // Mantener compatibilidad
          esEventoDeportivo: true
        };
      }
    } else {
      // Es un entero, buscar en eventos regulares
      const eventoIdInt = parseInt(eventoId);
      if (!isNaN(eventoIdInt)) {
        evento = await eventoRepository.findOne({
          where: { id: eventoIdInt, estado: "activo" }
        });
      }
    }

    if (!evento) {
      return handleErrorClient(
        res,
        404,
        "Error al participar",
        "El evento no existe o no está disponible"
      );
    }

    // Validar que la categoría esté permitida para este evento
    if (evento.esEventoDeportivo) {
      // Para eventos deportivos, verificar las categorías definidas en el evento
      const eventoDeportivo = await eventoDeportivoRepository.findOne({
        where: { id: eventoId }
      });
      
      if (eventoDeportivo && eventoDeportivo.categoria) {
        const categoriasPermitidas = eventoDeportivo.categoria.split(',').map(cat => cat.trim());
        if (!categoriasPermitidas.includes(categoria)) {
          return handleErrorClient(
            res,
            400,
            "Error al participar",
            `La categoría "${categoria}" no está disponible para este evento. Categorías permitidas: ${categoriasPermitidas.join(', ')}`
          );
        }
      }
    }

    // Manejar participación según el tipo de evento
    let participacionGuardada;
    
    if (evento.esEventoDeportivo) {
      // Es un evento deportivo, usar tabla específica
      const participacionExistente = await participacionDeportivaRepository.findOne({
        where: { eventoDeportivoId: eventoId, rutRamaExterna, categoria }
      });

      if (participacionExistente) {
        return handleErrorClient(
          res,
          400,
          "Error al participar",
          "Ya tienes una participación registrada en este evento para la categoría " + categoria
        );
      }

      const nuevaParticipacion = participacionDeportivaRepository.create({
        eventoDeportivoId: eventoId,
        rutRamaExterna,
        cantidadNinos,
        categoria,
        listaInvitados: listaInvitados || null,
      });

      participacionGuardada = await participacionDeportivaRepository.save(nuevaParticipacion);
    } else {
      // Es un evento regular, usar tabla original
      const participacionExistente = await participacionRepository.findOne({
        where: { eventoId: parseInt(eventoId), rutRamaExterna, categoria }
      });

      if (participacionExistente) {
        return handleErrorClient(
          res,
          400,
          "Error al participar",
          "Ya tienes una participación registrada en este evento para la categoría " + categoria
        );
      }

      const nuevaParticipacion = participacionRepository.create({
        eventoId: parseInt(eventoId),
        rutRamaExterna,
        cantidadNinos,
        categoria,
        listaInvitados: listaInvitados || null,
      });

      participacionGuardada = await participacionRepository.save(nuevaParticipacion);
    }

    handleSuccess(res, 201, "Participación registrada exitosamente", participacionGuardada);
  } catch (error) {
    console.error("Error al registrar participación:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener mis participaciones (filtrado por rol)
export async function obtenerMisParticipacionesEvento(req, res) {
  try {
    const rutUsuario = req.user.rut;
    const rolUsuario = req.user.rol;
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);
    const eventoRepository = AppDataSource.getRepository(Evento);

    // Importar repositorios para eventos deportivos
    const { AppDataSource: dataSource } = await import("../config/configDb.js");
    const EventoDeportivo = (await import("../entity/eventoDeportivo.entity.js")).default;
    const ParticipacionEventoDeportivo = (await import("../entity/participacionEventoDeportivo.entity.js")).default;
    const eventoDeportivoRepository = dataSource.getRepository(EventoDeportivo);
    const participacionDeportivaRepository = dataSource.getRepository(ParticipacionEventoDeportivo);

    // Definir filtros según el rol del usuario
    let filtroParticipacionesRegulares = {};
    let filtroParticipacionesDeportivas = {};

    if (rolUsuario === "directiva") {
      // Directiva ve todas las participaciones (sin filtro)
      filtroParticipacionesRegulares = {};
      filtroParticipacionesDeportivas = {};
    } else {
      // RamaExterna solo ve sus propias participaciones
      filtroParticipacionesRegulares = { rutRamaExterna: rutUsuario };
      filtroParticipacionesDeportivas = { rutRamaExterna: rutUsuario };
    }

    // Obtener participaciones en eventos regulares
    const participacionesRegulares = await participacionRepository.find({
      where: filtroParticipacionesRegulares,
      order: { eventoId: "ASC", categoria: "ASC" },
    });

    // Obtener participaciones en eventos deportivos
    const participacionesDeportivas = await participacionDeportivaRepository.find({
      where: filtroParticipacionesDeportivas,
      order: { categoria: "ASC" },
    });

    // Procesar participaciones regulares
    const eventosPorId = {};
    const participacionesRegularesConEventos = await Promise.all(
      participacionesRegulares.map(async (participacion) => {
        const evento = await eventoRepository.findOne({
          where: { id: participacion.eventoId }
        });
        
        if (evento) {
          if (!eventosPorId[evento.id]) {
            eventosPorId[evento.id] = {
              ...evento,
              participaciones: [],
              totalNinos: 0,
              categorias: [],
              esEventoDeportivo: false
            };
          }
          
          eventosPorId[evento.id].participaciones.push(participacion);
          eventosPorId[evento.id].totalNinos += participacion.cantidadNinos;
          eventosPorId[evento.id].categorias.push(participacion.categoria);
        }
        
        return {
          ...participacion,
          evento
        };
      })
    );

    // Procesar participaciones deportivas
    const participacionesDeportivasConEventos = await Promise.all(
      participacionesDeportivas.map(async (participacion) => {
        const eventoDeportivo = await eventoDeportivoRepository.findOne({
          where: { id: participacion.eventoDeportivoId }
        });
        
        if (eventoDeportivo) {
          // Convertir a formato compatible
          const eventoFormateado = {
            id: eventoDeportivo.id,
            nombre: eventoDeportivo.titulo,
            fecha: eventoDeportivo.fechaInicio,
            fechaFin: eventoDeportivo.fechaFin,
            descripcion: eventoDeportivo.descripcion,
            estado: eventoDeportivo.estado === "programado" || eventoDeportivo.estado === "confirmado" ? "activo" : eventoDeportivo.estado,
            lugar: eventoDeportivo.lugar,
            categoria: eventoDeportivo.categoria,
            tipoEvento: eventoDeportivo.tipoEvento,
            esEventoDeportivo: true,
            createdAt: eventoDeportivo.createdAt,
            updatedAt: eventoDeportivo.updatedAt
          };

          if (!eventosPorId[eventoDeportivo.id]) {
            eventosPorId[eventoDeportivo.id] = {
              ...eventoFormateado,
              participaciones: [],
              totalNinos: 0,
              categorias: [],
              esEventoDeportivo: true
            };
          }
          
          eventosPorId[eventoDeportivo.id].participaciones.push({
            ...participacion,
            eventoId: participacion.eventoDeportivoId // Para compatibilidad
          });
          eventosPorId[eventoDeportivo.id].totalNinos += participacion.cantidadNinos;
          eventosPorId[eventoDeportivo.id].categorias.push(participacion.categoria);
        }
        
        return {
          ...participacion,
          eventoId: participacion.eventoDeportivoId, // Para compatibilidad
          evento: eventoDeportivo
        };
      })
    );

    // Combinar todas las participaciones
    const todasLasParticipaciones = [...participacionesRegularesConEventos, ...participacionesDeportivasConEventos];

    handleSuccess(res, 200, "Participaciones obtenidas exitosamente", {
      participaciones: todasLasParticipaciones,
      eventosAgrupados: Object.values(eventosPorId)
    });
  } catch (error) {
    console.error("Error al obtener participaciones:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener categorías ya registradas por la rama en un evento específico
export async function obtenerCategoriasRegistradas(req, res) {
  try {
    const { eventoId } = req.params;
    const rutRamaExterna = req.user.rut;
    
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);
    
    // Importar repositorios para eventos deportivos
    const { AppDataSource: dataSource } = await import("../config/configDb.js");
    const ParticipacionEventoDeportivo = (await import("../entity/participacionEventoDeportivo.entity.js")).default;
    const participacionDeportivaRepository = dataSource.getRepository(ParticipacionEventoDeportivo);

    // Función para verificar si es un UUID válido
    const esUUID = (str) => {
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      return uuidRegex.test(str);
    };

    let participaciones = [];

    if (esUUID(eventoId)) {
      // Es un UUID, buscar en participaciones deportivas
      participaciones = await participacionDeportivaRepository.find({
        where: { eventoDeportivoId: eventoId, rutRamaExterna },
        order: { categoria: "ASC" },
      });
    } else {
      // Es un entero, buscar en participaciones regulares
      participaciones = await participacionRepository.find({
        where: { eventoId: parseInt(eventoId), rutRamaExterna },
        order: { categoria: "ASC" },
      });
    }

    const categoriasRegistradas = participaciones.map(p => p.categoria);
    
    // Lista de categorías predeterminadas (reducida según requerimiento)
    const categoriasPredeterminadas = ["sub-11", "sub-12", "sub-13"];
    
    // Obtener categorías dinámicas del evento deportivo específico si existe
    let categoriasDelEvento = [];
    if (esUUID(eventoId)) {
      const { AppDataSource: dataSource } = await import("../config/configDb.js");
      const EventoDeportivo = (await import("../entity/eventoDeportivo.entity.js")).default;
      const eventoDeportivoRepository = dataSource.getRepository(EventoDeportivo);
      
      const eventoDeportivo = await eventoDeportivoRepository.findOne({
        where: { id: eventoId }
      });
      
      if (eventoDeportivo && eventoDeportivo.categoria) {
        categoriasDelEvento = eventoDeportivo.categoria.split(',').map(cat => cat.trim());
      }
    }
    
    // Combinar categorías predeterminadas con las del evento
    const todasCategorias = [...new Set([...categoriasPredeterminadas, ...categoriasDelEvento])];
    
    const categoriasDisponibles = todasCategorias.filter(cat => !categoriasRegistradas.includes(cat));

    handleSuccess(res, 200, "Categorías obtenidas exitosamente", {
      categoriasRegistradas,
      categoriasDisponibles,
      participaciones,
      esEventoDeportivo: esUUID(eventoId)
    });
  } catch (error) {
    console.error("Error al obtener categorías registradas:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Actualizar evento (directiva)
export async function actualizarEvento(req, res) {
  try {
    const { id } = req.params;
    const { nombre, fecha, descripcion, estado } = req.body;

    const eventoRepository = AppDataSource.getRepository(Evento);

    const evento = await eventoRepository.findOne({ where: { id: parseInt(id) } });

    if (!evento) {
      return handleErrorClient(res, 404, "Evento no encontrado");
    }

    // Actualizar campos si se proporcionan
    if (nombre) evento.nombre = nombre;
    if (fecha) evento.fecha = new Date(fecha);
    if (descripcion !== undefined) evento.descripcion = descripcion;
    if (estado) evento.estado = estado;

    const eventoActualizado = await eventoRepository.save(evento);

    handleSuccess(res, 200, "Evento actualizado exitosamente", eventoActualizado);
  } catch (error) {
    console.error("Error al actualizar evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Eliminar evento (directiva)
export async function eliminarEvento(req, res) {
  try {
    const { id } = req.params;

    const eventoRepository = AppDataSource.getRepository(Evento);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);

    const evento = await eventoRepository.findOne({ where: { id: parseInt(id) } });

    if (!evento) {
      return handleErrorClient(res, 404, "Evento no encontrado");
    }

    // Verificar si hay participaciones
    const participaciones = await participacionRepository.count({
      where: { eventoId: parseInt(id) }
    });

    if (participaciones > 0) {
      return handleErrorClient(
        res,
        400,
        "No se puede eliminar el evento",
        "El evento tiene participaciones registradas. Cámbialo a estado 'cancelado' en su lugar."
      );
    }

    await eventoRepository.remove(evento);

    handleSuccess(res, 200, "Evento eliminado exitosamente");
  } catch (error) {
    console.error("Error al eliminar evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}

// Obtener participaciones de un evento (directiva) 
export async function obtenerParticipacionesEvento(req, res) {
  try {
    const { id } = req.params;

    const participacionRepository = AppDataSource.getRepository(ParticipacionEvento);
    const userRepository = AppDataSource.getRepository(User);

    // Importar repositorios para eventos deportivos
    const { AppDataSource: dataSource } = await import("../config/configDb.js");
    const ParticipacionEventoDeportivo = (await import("../entity/participacionEventoDeportivo.entity.js")).default;
    const participacionDeportivaRepository = dataSource.getRepository(ParticipacionEventoDeportivo);

    // Función para verificar si es un UUID válido
    const esUUID = (str) => {
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      return uuidRegex.test(str);
    };

    let participaciones = [];

    if (esUUID(id)) {
      // Es un UUID, buscar en participaciones deportivas
      participaciones = await participacionDeportivaRepository.find({
        where: { eventoDeportivoId: id },
        order: { categoria: "ASC", createdAt: "DESC" },
      });
    } else {
      // Es un entero, buscar en participaciones regulares
      const eventoIdInt = parseInt(id);
      if (!isNaN(eventoIdInt)) {
        participaciones = await participacionRepository.find({
          where: { eventoId: eventoIdInt },
          order: { categoria: "ASC", createdAt: "DESC" },
        });
      }
    }

    // Obtener información de los usuarios y agrupar por rama deportiva
    const participacionesConUsuarios = await Promise.all(
      participaciones.map(async (participacion) => {
        const usuario = await userRepository.findOne({
          where: { rut: participacion.rutRamaExterna }
        });
        return {
          ...participacion,
          ramaExterna: usuario,
          nombreRama: usuario ? usuario.nombre : "Rama no identificada"
        };
      })
    );

    // Agrupar y calcular estadísticas por rama y categoría
    const estadisticasPorRama = {};
    let totalGeneral = 0;

    participacionesConUsuarios.forEach(participacion => {
      const nombreRama = participacion.nombreRama;
      const categoria = participacion.categoria;
      
      if (!estadisticasPorRama[nombreRama]) {
        estadisticasPorRama[nombreRama] = {
          nombreRama,
          rut: participacion.rutRamaExterna,
          participaciones: [],
          totalPorCategoria: {},
          totalRama: 0
        };
      }

      estadisticasPorRama[nombreRama].participaciones.push(participacion);
      
      if (!estadisticasPorRama[nombreRama].totalPorCategoria[categoria]) {
        estadisticasPorRama[nombreRama].totalPorCategoria[categoria] = 0;
      }
      
      estadisticasPorRama[nombreRama].totalPorCategoria[categoria] += participacion.cantidadNinos;
      estadisticasPorRama[nombreRama].totalRama += participacion.cantidadNinos;
      totalGeneral += participacion.cantidadNinos;
    });

    const resumen = {
      participaciones: participacionesConUsuarios,
      estadisticasPorRama: Object.values(estadisticasPorRama),
      totalGeneral
    };

    handleSuccess(res, 200, "Participaciones del evento obtenidas exitosamente", resumen);
  } catch (error) {
    console.error("Error al obtener participaciones del evento:", error);
    handleErrorServer(res, 500, error.message);
  }
}