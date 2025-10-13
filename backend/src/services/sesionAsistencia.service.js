import { AppDataSource } from "../config/configDb.js";
import { SesionAsistenciaSchema } from "../entity/sesionAsistencia.entity.js";
import { RegistroAsistenciaSchema } from "../entity/registroAsistencia.entity.js";

export const createSesionAsistenciaService = async (sesionData, registrosData, entrenadorInfo) => {
  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    const sesionRepository = queryRunner.manager.getRepository(SesionAsistenciaSchema);
    const registroRepository = queryRunner.manager.getRepository(RegistroAsistenciaSchema);

    console.log('📝 Creando sesión de asistencia...');
    console.log('🔍 Datos de sesión:', sesionData);
    console.log('👨‍🏫 Entrenador:', entrenadorInfo);

    // Crear la sesión de asistencia
    const nuevaSesion = sesionRepository.create({
      nombre: sesionData.nombre,
      descripcion: sesionData.descripcion || '',
      fecha: sesionData.fecha,
      curso: sesionData.curso,
      rutEntrenador: entrenadorInfo.rut,
      nombreEntrenador: entrenadorInfo.nombreCompleto,
    });

    const sesionGuardada = await sesionRepository.save(nuevaSesion);
    console.log('✅ Sesión creada con ID:', sesionGuardada.id);

    // Crear los registros de asistencia
    const registrosParaGuardar = registrosData.map(registro => ({
      sesionId: sesionGuardada.id,
      rutEstudiante: registro.rutEstudiante,
      nombreEstudiante: registro.nombreEstudiante,
      estado: registro.estado,
      observaciones: registro.observaciones || null,
    }));

    const registrosGuardados = await registroRepository.save(registrosParaGuardar);
    console.log('✅ Registros de asistencia creados:', registrosGuardados.length);

    await queryRunner.commitTransaction();

    return [sesionGuardada, null];
  } catch (error) {
    await queryRunner.rollbackTransaction();
    console.error('❌ Error al crear sesión de asistencia:', error);
    return [null, error];
  } finally {
    await queryRunner.release();
  }
};

export const getSesionesByEntrenadorService = async (rutEntrenador, limite = 50) => {
  try {
    const sesionRepository = AppDataSource.getRepository(SesionAsistenciaSchema);
    
    const sesiones = await sesionRepository.find({
      where: { rutEntrenador },
      order: { createdAt: 'DESC' },
      take: limite,
    });

    console.log(`✅ Sesiones encontradas para entrenador ${rutEntrenador}:`, sesiones.length);
    return [sesiones, null];
  } catch (error) {
    console.error('❌ Error al obtener sesiones:', error);
    return [null, error];
  }
};

export const getSesionConRegistrosService = async (sesionId) => {
  try {
    const sesionRepository = AppDataSource.getRepository(SesionAsistenciaSchema);
    const registroRepository = AppDataSource.getRepository(RegistroAsistenciaSchema);

    const sesion = await sesionRepository.findOne({
      where: { id: sesionId }
    });

    if (!sesion) {
      return [null, { message: 'Sesión no encontrada' }];
    }

    const registros = await registroRepository.find({
      where: { sesionId },
      order: { nombreEstudiante: 'ASC' },
    });

    return [{ ...sesion, registros }, null];
  } catch (error) {
    console.error('❌ Error al obtener sesión con registros:', error);
    return [null, error];
  }
};

export const getEstadisticasAsistenciaService = async (curso = null, fechaDesde = null, fechaHasta = null) => {
  try {
    const registroRepository = AppDataSource.getRepository(RegistroAsistenciaSchema);
    const sesionRepository = AppDataSource.getRepository(SesionAsistenciaSchema);

    let whereConditions = {};
    if (curso) {
      // Primero obtener las sesiones del curso
      const sesionesCurso = await sesionRepository.find({
        where: { curso },
        select: ['id']
      });
      
      if (sesionesCurso.length === 0) {
        return [{
          totalRegistros: 0,
          presentes: 0,
          ausentes: 0,
          justificados: 0,
          porcentajeAsistencia: 0
        }, null];
      }

      whereConditions.sesionId = sesionesCurso.map(s => s.id);
    }

    const totalRegistros = await registroRepository.count({ where: whereConditions });
    const presentes = await registroRepository.count({ 
      where: { ...whereConditions, estado: 'presente' }
    });
    const ausentes = await registroRepository.count({ 
      where: { ...whereConditions, estado: 'ausente' }
    });
    const justificados = await registroRepository.count({ 
      where: { ...whereConditions, estado: 'justificado' }
    });

    const porcentajeAsistencia = totalRegistros > 0 
      ? Math.round((presentes / totalRegistros) * 100) 
      : 0;

    return [{
      totalRegistros,
      presentes,
      ausentes,
      justificados,
      porcentajeAsistencia
    }, null];
  } catch (error) {
    console.error('❌ Error al obtener estadísticas:', error);
    return [null, error];
  }
};