"use strict";
import { AppDataSource } from "./configDb.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";
import User from "../entity/user.entity.js";
import TipoEvento from "../entity/tipoEvento.entity.js";


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

  } catch (error) {
    console.error("❌ Error al crear datos iniciales:", error);
  }
}



export { createInitialData };
