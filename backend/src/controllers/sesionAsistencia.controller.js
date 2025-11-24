import { 
  createSesionAsistenciaService, 
  getSesionesByEntrenadorService,
  getSesionConRegistrosService,
  getEstadisticasAsistenciaService,
  getAllSesionesService
} from "../services/sesionAsistencia.service.js";
import { obtenerUserByRut } from "../services/user.service.js";
import { getEstudiantesByRutListService } from "../services/estudiante.service.js";
import { AppDataSource } from "../config/configDb.js";

export const createSesionAsistencia = async (req, res) => {
  try {
    const { nombre, descripcion, fecha, categoria, asistencias } = req.body;
    const userAuth = req.user;

    console.log('📝 Creando nueva sesión de asistencia');
    console.log('👤 Usuario autenticado:', userAuth.rut);
    console.log('📊 Datos recibidos:', { nombre, categoria, fecha, asistencias: asistencias?.length });

    // Validaciones
    if (!nombre || !fecha || !categoria || !asistencias || !Array.isArray(asistencias)) {
      return res.status(400).json({
        success: false,
        message: 'Datos incompletos. Se requiere nombre, fecha, categoria y asistencias.'
      });
    }

    if (asistencias.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Debe incluir al menos un registro de asistencia.'
      });
    }

    // Obtener información del entrenador
    const [entrenador, entrenadorError] = await obtenerUserByRut(userAuth.rut);
    if (entrenadorError || !entrenador) {
      return res.status(404).json({
        success: false,
        message: 'Entrenador no encontrado'
      });
    }

    // Obtener nombres de estudiantes de la base de datos
    const rutEstudiantes = asistencias.map(a => a.rutEstudiante);
    const [estudiantes, estudiantesError] = await getEstudiantesByRutListService(rutEstudiantes);
    
    if (estudiantesError) {
      console.warn('⚠️ Error al obtener nombres de estudiantes, usando datos del frontend');
    }

    // Enriquecer datos de asistencia con nombres de la BD
    const asistenciasEnriquecidas = asistencias.map(asistencia => {
      const estudiante = estudiantes?.find(e => e.rut === asistencia.rutEstudiante);
      return {
        ...asistencia,
        nombreEstudiante: estudiante?.nombre || `Estudiante ${asistencia.rutEstudiante}`,
      };
    });

    // Crear sesión y registros
    const sesionData = {
      nombre: nombre.trim(),
      descripcion: descripcion?.trim() || '',
      fecha: new Date(fecha),
      curso: categoria.trim(), // Guardar categoria como curso en la BD
    };

    const [sesionCreada, error] = await createSesionAsistenciaService(
      sesionData,
      asistenciasEnriquecidas,
      {
        rut: entrenador.rut,
        nombreCompleto: entrenador.nombreCompleto
      }
    );

    if (error) {
      console.error('❌ Error al crear sesión:', error);
      return res.status(500).json({
        success: false,
        message: 'Error interno al crear la sesión de asistencia'
      });
    }

    console.log('✅ Sesión de asistencia creada exitosamente:', sesionCreada.id);

    res.status(201).json({
      success: true,
      message: 'Sesión de asistencia creada exitosamente',
      data: {
        sesionId: sesionCreada.id,
        nombre: sesionCreada.nombre,
        curso: sesionCreada.curso,
        fecha: sesionCreada.fecha,
        registros: asistenciasEnriquecidas.length
      }
    });

  } catch (error) {
    console.error('❌ Error en createSesionAsistencia:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

export const getMisSesiones = async (req, res) => {
  try {
    const userAuth = req.user;
    const limite = parseInt(req.query.limite) || 50;

    console.log('📋 Obteniendo sesiones del entrenador:', userAuth.rut);

    const [sesiones, error] = await getSesionesByEntrenadorService(userAuth.rut, limite);

    if (error) {
      console.error('❌ Error al obtener sesiones:', error);
      return res.status(500).json({
        success: false,
        message: 'Error al obtener las sesiones'
      });
    }

    console.log('✅ Sesiones encontradas:', sesiones.length);

    res.json({
      success: true,
      data: sesiones,
      total: sesiones.length
    });

  } catch (error) {
    console.error('❌ Error en getMisSesiones:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

export const getCategorias = async (req, res) => {
  try {
    const estudianteRepo = AppDataSource.getRepository('Estudiante');
    
    // Obtener categorías únicas de estudiantes activos
    const result = await estudianteRepo
      .createQueryBuilder('estudiante')
      .select('DISTINCT estudiante.categoria', 'categoria')
      .where('estudiante.estado = :estado', { estado: 'activo' })
      .andWhere('estudiante.categoria IS NOT NULL')
      .andWhere("estudiante.categoria != ''")
      .orderBy('estudiante.categoria', 'ASC')
      .getRawMany();

    const categorias = result.map(r => r.categoria);

    console.log('✅ Categorías obtenidas:', categorias);

    res.json({
      success: true,
      categorias: categorias
    });

  } catch (error) {
    console.error('❌ Error en getCategorias:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener categorías'
    });
  }
};

export const getSesionDetalle = async (req, res) => {
  try {
    const { sesionId } = req.params;
    const userAuth = req.user;

    console.log('🔍 Obteniendo detalles de sesión:', sesionId);

    const [sesionConRegistros, error] = await getSesionConRegistrosService(parseInt(sesionId));

    if (error) {
      console.error('❌ Error al obtener sesión:', error);
      return res.status(404).json({
        success: false,
        message: error.message || 'Sesión no encontrada'
      });
    }

    // Verificar que la sesión pertenece al entrenador autenticado
    if (sesionConRegistros.rutEntrenador !== userAuth.rut) {
      return res.status(403).json({
        success: false,
        message: 'No tienes permiso para ver esta sesión'
      });
    }

    console.log('✅ Sesión encontrada con', sesionConRegistros.registros.length, 'registros');

    res.json({
      success: true,
      data: sesionConRegistros
    });

  } catch (error) {
    console.error('❌ Error en getSesionDetalle:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

export const getEstadisticasAsistencia = async (req, res) => {
  try {
    const { curso, fechaDesde, fechaHasta } = req.query;

    console.log('📊 Obteniendo estadísticas de asistencia');
    console.log('🔍 Filtros:', { curso, fechaDesde, fechaHasta });

    const [estadisticas, error] = await getEstadisticasAsistenciaService(
      curso || null,
      fechaDesde ? new Date(fechaDesde) : null,
      fechaHasta ? new Date(fechaHasta) : null
    );

    if (error) {
      console.error('❌ Error al obtener estadísticas:', error);
      return res.status(500).json({
        success: false,
        message: 'Error al obtener estadísticas'
      });
    }

    console.log('✅ Estadísticas calculadas:', estadisticas);

    res.json({
      success: true,
      data: estadisticas
    });

  } catch (error) {
    console.error('❌ Error en getEstadisticasAsistencia:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};

export const getAllSesiones = async (req, res) => {
  try {
    const userAuth = req.user;
    const limite = parseInt(req.query.limite) || 50;
    const curso = req.query.curso || req.query.categoria || null;

    console.log('📋 Obteniendo sesiones');
    console.log('👤 Usuario:', userAuth.rut, 'Rol:', userAuth.rol);
    console.log('🔍 Filtros:', { limite, curso });

    let sesiones, error;

    // Si es directiva o apoderado, obtener TODAS las sesiones
    if (userAuth.rol === 'directiva' || userAuth.rol === 'apoderado') {
      [sesiones, error] = await getAllSesionesService(limite, curso);
    } else if (userAuth.rol === 'entrenador') {
      // Si es entrenador, solo sus sesiones
      [sesiones, error] = await getSesionesByEntrenadorService(userAuth.rut, limite);
    } else {
      // Rol no válido
      return res.status(403).json({
        success: false,
        message: 'Rol no autorizado para acceder a este recurso'
      });
    }

    if (error) {
      console.error('❌ Error al obtener sesiones:', error);
      return res.status(500).json({
        success: false,
        message: 'Error al obtener las sesiones'
      });
    }

    console.log('✅ Total de sesiones encontradas:', sesiones.length);

    res.json({
      success: true,
      data: sesiones,
      total: sesiones.length
    });

  } catch (error) {
    console.error('❌ Error en getAllSesiones:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
};