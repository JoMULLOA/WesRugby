"use strict";
import { AppDataSource } from "./configDb.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";
import User from "../entity/user.entity.js";
import TipoEvento from "../entity/tipoEvento.entity.js";
import EventoDeportivo from "../entity/eventoDeportivo.entity.js";
import ParticipacionEventoDeportivo from "../entity/participacionEventoDeportivo.entity.js";


//Los ruts estan hasta un maximo de 29.999.999-9, por lo que no se pueden crear usuarios con ruts mayores a ese valor, se creara, 
//pero no se podra buscar como un amigo.
async function createInitialData() {
  try {
    // Crear Usuarios Base del Sistema Wessex Rugby
    const userRepository = AppDataSource.getRepository(User);
    const userCount = await userRepository.count();

    if (userCount === 0) {
      
      // Usuario 1: Directiva - Máximo nivel de acceso
      const userDirectiva = userRepository.create({
        rut: "12.345.678-9",
        nombreCompleto: "Director Wessex Rugby",
        email: "directiva@ubiobio.cl",
        password: await encryptPassword("Directiva2024"),
        rol: "directiva",
      });

      // Usuario 2: Tesorera - Gestión financiera
      const userTesorera = userRepository.create({
        rut: "23.456.789-0",
        nombreCompleto: "Tesorera Wessex Rugby",
        email: "tesorera@ubiobio.cl",
        password: await encryptPassword("Tesorera2024"),
        rol: "tesorera",
      });

      // Usuario 3: Entrenador - Gestión deportiva
      const userEntrenador = userRepository.create({
        rut: "34.567.890-1",
        nombreCompleto: "Entrenador Wessex Rugby",
        email: "entrenador@ubiobio.cl",
        password: await encryptPassword("Entrenador2024"),
        rol: "entrenador",
      });

      // Usuario 4: Apoderado - Acceso limitado
      const userApoderado = userRepository.create({
        rut: "45.678.901-2",
        nombreCompleto: "Apoderado Demo Wessex",
        email: "apoderado@ubiobio.cl",
        password: await encryptPassword("Apoderado2024"),
        rol: "apoderado",
      });

      // Usuario 5: RamaExterna - Gestión de eventos deportivos
      const userRamaExterna = userRepository.create({
        rut: "56.789.012-3",
        nombreCompleto: "Rama Externa Rugby Sub-12",
        email: "coordinador@ubiobio.cl",
        password: await encryptPassword("Coordinador2024"),
        rol: "RamaExterna",
      });

      await userRepository.save([userDirectiva, userTesorera, userEntrenador, userApoderado, userRamaExterna]);
      
      console.log("✅ Usuarios del sistema Wessex Rugby creados exitosamente:");
      console.log("   - Directiva: directiva@ubiobio.cl / Directiva2024");
      console.log("   - Tesorera: tesorera@ubiobio.cl / Tesorera2024");
      console.log("   - Entrenador: entrenador@ubiobio.cl / Entrenador2024");
      console.log("   - Apoderado: apoderado@ubiobio.cl / Apoderado2024");
      console.log("   - RamaExterna: coordinador@ubiobio.cl / Coordinador2024");

      // Mantener referencia para creación de otros datos
      const user1 = userDirectiva;
      const user2 = userTesorera;
      const user3 = userEntrenador;

    } else {
      console.log("Usuarios del sistema ya existen, cargando referencias...");
    }

    await ensureSampleRamaUsers(userRepository);


    // Crear Tipos de Evento por defecto
    const tipoEventoRepository = AppDataSource.getRepository(TipoEvento);
    const tipoEventoCount = await tipoEventoRepository.count();

    if (tipoEventoCount === 0) {
      const tiposEventoDefecto = [
        { nombre: "Entrenamiento", esDeportivo: true },
        { nombre: "Partido", esDeportivo: true },
        { nombre: "Torneo", esDeportivo: true },
        { nombre: "Reunión", esDeportivo: false },
        { nombre: "Evento Social", esDeportivo: false },
        { nombre: "Viaje", esDeportivo: false },
        { nombre: "Otro", esDeportivo: false }
      ];

      const tiposCreados = tiposEventoDefecto.map(tipo => 
        tipoEventoRepository.create({
          nombre: tipo.nombre,
          esDeportivo: tipo.esDeportivo,
          activo: true
        })
      );

      await tipoEventoRepository.save(tiposCreados);
      
      console.log("✅ Tipos de evento creados exitosamente:");
      tiposEventoDefecto.forEach(tipo => {
        console.log(`   - ${tipo.nombre} (${tipo.esDeportivo ? 'Deportivo' : 'No deportivo'})`);
      });
    } else {
      console.log("Tipos de evento ya existen...");
    }

    await ensureDemoEventoDeportivo(userRepository, tipoEventoRepository);

  } catch (error) {
    console.error("Error al crear datos iniciales:", error);
  }
}

async function ensureSampleRamaUsers(userRepository) {
  try {
    const sampleRamas = [
      {
        rut: "56.789.012-3",
        nombreCompleto: "Rama Externa Rugby Sub-12",
        email: "coordinador@ubiobio.cl",
      },
      {
        rut: "57.321.654-1",
        nombreCompleto: "Rama Externa Rugby Sub-11",
        email: "rama.sub11@ubiobio.cl",
      },
      {
        rut: "58.654.321-9",
        nombreCompleto: "Rama Externa Femenina Sub-13",
        email: "rama.sub13@ubiobio.cl",
      },
    ];

    for (const sample of sampleRamas) {
      const existing = await userRepository.findOne({
        where: { rut: sample.rut },
      });

      if (!existing) {
        const demoUser = userRepository.create({
          rut: sample.rut,
          nombreCompleto: sample.nombreCompleto,
          email: sample.email,
          password: await encryptPassword("Rama2024"),
          rol: "RamaExterna",
        });

        await userRepository.save(demoUser);
        console.log(`   - RamaExterna demo creada: ${sample.email} / Rama2024`);
      }
    }
  } catch (error) {
    console.error("Error asegurando ramas deportivas demo:", error);
  }
}

async function ensureDemoEventoDeportivo(userRepository, tipoEventoRepository) {
  try {
    const eventoRepository = AppDataSource.getRepository(EventoDeportivo);
    const participacionRepository = AppDataSource.getRepository(ParticipacionEventoDeportivo);

    const demoTitle = "Clinica Deportiva Multicategoria";
    let eventoDemo = await eventoRepository.findOne({
      where: { titulo: demoTitle },
    });

    const organizador = await userRepository.findOne({
      where: { rol: "directiva" },
    });

    if (!organizador) {
      console.warn("No se encontro usuario directiva para crear evento demo.");
      return;
    }

    let tipoDeportivo = await tipoEventoRepository.findOne({
      where: { nombre: "Partido", activo: true },
    });

    if (!tipoDeportivo) {
      tipoDeportivo = await tipoEventoRepository.findOne({
        where: { esDeportivo: true, activo: true },
      });
    }

    if (!tipoDeportivo) {
      console.warn("No se encontro tipo de evento deportivo activo para crear el demo.");
      return;
    }

    if (!eventoDemo) {
      const fechaInicio = new Date();
      fechaInicio.setDate(fechaInicio.getDate() + 7);
      const fechaFin = new Date(fechaInicio.getTime() + 2 * 60 * 60 * 1000);

      eventoDemo = eventoRepository.create({
        titulo: demoTitle,
        descripcion: "Evento demostrativo con multiples ramas y categorias para pruebas internas.",
        tipoEventoId: tipoDeportivo.id,
        categoria: "sub-11,sub-12,sub-13",
        fechaInicio,
        fechaFin,
        lugar: "Cancha Principal Wessex",
        estado: "programado",
        organizadoPorRut: organizador.rut,
        notificarParticipantes: false,
      });

      await eventoRepository.save(eventoDemo);
      console.log("   - Evento deportivo demo creado para pruebas");
    }

    const participacionesExistentes = await participacionRepository.count({
      where: { eventoDeportivoId: eventoDemo.id },
    });

    if (participacionesExistentes === 0) {
      const participacionesDemo = [
        { rutRamaExterna: "56.789.012-3", categoria: "sub-12", cantidadNinos: 16 },
        { rutRamaExterna: "56.789.012-3", categoria: "sub-13", cantidadNinos: 9 },
        { rutRamaExterna: "57.321.654-1", categoria: "sub-11", cantidadNinos: 18 },
        { rutRamaExterna: "57.321.654-1", categoria: "sub-12", cantidadNinos: 7 },
        { rutRamaExterna: "58.654.321-9", categoria: "sub-13", cantidadNinos: 14 },
      ];

      const registros = participacionesDemo.map((item) =>
        participacionRepository.create({
          ...item,
          eventoDeportivoId: eventoDemo.id,
        }),
      );

      await participacionRepository.save(registros);
      console.log("   - Participaciones demo creadas para el evento deportivo de ejemplo");
    }
  } catch (error) {
    console.error("Error asegurando evento deportivo demo:", error);
  }
}

export { createInitialData };
