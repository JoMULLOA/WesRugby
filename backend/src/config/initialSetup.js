"use strict";
import { AppDataSource } from "./configDb.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";
import User from "../entity/user.entity.js";
import TipoEvento from "../entity/tipoEvento.entity.js";
import EventoDeportivo from "../entity/eventoDeportivo.entity.js";
import { seedInventoryProducts } from "../services/inventory.service.js";


//Los ruts estan hasta un maximo de 29.999.999-9, por lo que no se pueden crear usuarios con ruts mayores a ese valor, se creara, 
//pero no se podra buscar como un amigo.
async function createInitialData() {
  try {
    // Crear Usuarios Base del Sistema Wessex Rugby
    const userRepository = AppDataSource.getRepository(User);
    const userCount = await userRepository.count();

    if (userCount === 0) {
      
      // Usuario 1: Directiva - MÃ¡ximo nivel de acceso
      const userDirectiva = userRepository.create({
        rut: "12.345.678-9",
        nombreCompleto: "Director Wessex Rugby",
        email: "directiva@wessex.cl",
        password: await encryptPassword("Directiva2024"),
        rol: "directiva",
      });

      // Usuario 2: Tesorera - GestiÃ³n financiera
      const userTesorera = userRepository.create({
        rut: "23.456.789-0",
        nombreCompleto: "Tesorera Wessex Rugby",
        email: "tesorera@wessex.cl",
        password: await encryptPassword("Tesorera2024"),
        rol: "tesorera",
      });

      // Usuario 3: Entrenador - GestiÃ³n deportiva
      const userEntrenador = userRepository.create({
        rut: "34.567.890-1",
        nombreCompleto: "Entrenador Wessex Rugby",
        email: "entrenador@wessex.cl",
        password: await encryptPassword("Entrenador2024"),
        rol: "entrenador",
      });

      // Usuario 4: Apoderado - Acceso limitado
      const userApoderado = userRepository.create({
        rut: "45.678.901-2",
        nombreCompleto: "Apoderado Demo Wessex",
        email: "apoderado@wessex.cl",
        password: await encryptPassword("Apoderado2024"),
        rol: "apoderado",
      });

      // Usuario 5: RamaExterna - GestiÃ³n de eventos deportivos
      const userRamaExterna = userRepository.create({
        rut: "56.789.012-3",
        nombreCompleto: "Rama Externa Rugby M10",
        email: "coordinador@wessex.cl",
        password: await encryptPassword("Coordinador2024"),
        rol: "RamaExterna",
      });

      await userRepository.save([userDirectiva, userTesorera, userEntrenador, userApoderado, userRamaExterna]);
      
      console.log("âœ… Usuarios del sistema Wessex Rugby creados exitosamente:");
      console.log("   - Directiva: directiva@wessex.cl / Directiva2024");
      console.log("   - Tesorera: tesorera@wessex.cl / Tesorera2024");
      console.log("   - Entrenador: entrenador@wessex.cl / Entrenador2024");
      console.log("   - Apoderado: apoderado@wessex.cl / Apoderado2024");
      console.log("   - RamaExterna: coordinador@wessex.cl / Coordinador2024");

      // Mantener referencia para creaciÃ³n de otros datos
      const user1 = userDirectiva;
      const user2 = userTesorera;
      const user3 = userEntrenador;

    } else {
      console.log("Usuarios del sistema ya existen, cargando referencias...");
    }

    await ensureSampleEntrenadores(userRepository);
    await ensureSampleRamaUsers(userRepository);
    await removeLegacyDemoEvents();


    // Crear Tipos de Evento por defecto
    const tipoEventoRepository = AppDataSource.getRepository(TipoEvento);
    const tipoEventoCount = await tipoEventoRepository.count();

    if (tipoEventoCount === 0) {
      const tiposEventoDefecto = [
        { nombre: "Entrenamiento", esDeportivo: true },
        { nombre: "Partido", esDeportivo: true },
        { nombre: "Torneo", esDeportivo: true },
        { nombre: "ReuniÃ³n", esDeportivo: false },
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
      
      console.log("âœ… Tipos de evento creados exitosamente:");
      tiposEventoDefecto.forEach(tipo => {
        console.log(`   - ${tipo.nombre} (${tipo.esDeportivo ? 'Deportivo' : 'No deportivo'})`);
      });
    } else {
      console.log("Tipos de evento ya existen...");
    }

    await seedInventoryProducts();

  } catch (error) {
    console.error("Error al crear datos iniciales:", error);
  }
}

async function ensureSampleEntrenadores(userRepository) {
  try {
    const sampleEntrenadores = [
      {
        rut: "34.567.890-1",
        nombreCompleto: "Carlos Rodriguez Martinez",
        email: "entrenador@wessex.cl",
      },
      {
        rut: "15.234.678-5",
        nombreCompleto: "María González Perez",
        email: "maria.gonzalez@wessex.cl",
      },
      {
        rut: "16.345.789-2",
        nombreCompleto: "Juan Pablo Fernandez",
        email: "juan.fernandez@wessex.cl",
      },
      {
        rut: "17.456.890-9",
        nombreCompleto: "Patricia Silva Castro",
        email: "patricia.silva@wessex.cl",
      },
      {
        rut: "18.567.901-6",
        nombreCompleto: "Diego Muñoz Valdes",
        email: "diego.munoz@wessex.cl",
      },
      {
        rut: "19.678.012-3",
        nombreCompleto: "Carolina Ramirez Lopez",
        email: "carolina.ramirez@wessex.cl",
      },
      {
        rut: "20.789.123-0",
        nombreCompleto: "Andrés Torres Gutierrez",
        email: "andres.torres@wessex.cl",
      },
      {
        rut: "21.890.234-7",
        nombreCompleto: "Francisca Morales Diaz",
        email: "francisca.morales@wessex.cl",
      },
    ];

    for (const sample of sampleEntrenadores) {
      const existing = await userRepository.findOne({
        where: { rut: sample.rut },
      });

      if (!existing) {
        const entrenador = userRepository.create({
          rut: sample.rut,
          nombreCompleto: sample.nombreCompleto,
          email: sample.email,
          password: await encryptPassword("Entrenador2024"),
          rol: "entrenador",
        });

        await userRepository.save(entrenador);
        console.log(`   - Entrenador creado: ${sample.nombreCompleto} (${sample.email})`);
      }
    }
    console.log("✅ Entrenadores de ejemplo verificados/creados");
  } catch (error) {
    console.error("Error asegurando entrenadores de ejemplo:", error);
  }
}

async function ensureSampleRamaUsers(userRepository) {
  try {
    const sampleRamas = [
      {
        rut: "56.789.012-3",
        nombreCompleto: "Rama Externa Rugby M10",
        email: "coordinador@wessex.cl",
      },
      {
        rut: "57.321.654-1",
        nombreCompleto: "Rama Externa Rugby M6",
        email: "rama.m6@wessex.cl",
      },
      {
        rut: "58.654.321-9",
        nombreCompleto: "Rama Externa Femenina M12",
        email: "rama.m12@wessex.cl",
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

async function removeLegacyDemoEvents() {
  try {
    const eventoRepository = AppDataSource.getRepository(EventoDeportivo);
    const demoTitles = [
      "Clinica Deportiva Multicategoria",
      "Clínica Deportiva Multicategoria",
    ];

    let removed = 0;
    for (const titulo of demoTitles) {
      const result = await eventoRepository.delete({ titulo });
      removed += result.affected ?? 0;
    }

    if (removed > 0) {
      console.log(`Eventos demo eliminados: ${removed}`);
    }
  } catch (error) {
    console.error("Error eliminando eventos demo legacy:", error);
  }
}

export { createInitialData };
