"use strict";
import { AppDataSource } from "./configDb.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";
import User from "../entity/user.entity.js";


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
        genero: "masculino",
        fechaNacimiento: "1980-01-15",
        carrera: "Administración Deportiva",
        rol: "directiva",
        puntuacion: 5,
        cantidadValoraciones: 0,
        contadorReportes: 0,
        saldo: 0,
      });

      // Usuario 2: Tesorera - Gestión financiera
      const userTesorera = userRepository.create({
        rut: "23.456.789-0",
        nombreCompleto: "Tesorera Wessex Rugby",
        email: "tesorera@ubiobio.cl",
        password: await encryptPassword("Tesorera2024"),
        genero: "femenino",
        fechaNacimiento: "1985-03-22",
        carrera: "Contabilidad",
        rol: "tesorera",
        puntuacion: 5,
        cantidadValoraciones: 0,
        contadorReportes: 0,
        saldo: 0,
      });

      // Usuario 3: Entrenador - Gestión deportiva
      const userEntrenador = userRepository.create({
        rut: "34.567.890-1",
        nombreCompleto: "Entrenador Wessex Rugby",
        email: "entrenador@ubiobio.cl",
        password: await encryptPassword("Entrenador2024"),
        genero: "masculino",
        fechaNacimiento: "1982-07-10",
        carrera: "Educación Física",
        rol: "entrenador",
        puntuacion: 5,
        cantidadValoraciones: 0,
        contadorReportes: 0,
        saldo: 0,
      });

      // Usuario 4: Apoderado - Acceso limitado
      const userApoderado = userRepository.create({
        rut: "45.678.901-2",
        nombreCompleto: "Apoderado Demo Wessex",
        email: "apoderado@ubiobio.cl",
        password: await encryptPassword("Apoderado2024"),
        genero: "femenino",
        fechaNacimiento: "1975-11-05",
        carrera: "Ingeniería Comercial",
        rol: "apoderado",
        puntuacion: 5,
        cantidadValoraciones: 0,
        contadorReportes: 0,
        saldo: 0,
      });

      await userRepository.save([userDirectiva, userTesorera, userEntrenador, userApoderado]);
      
      console.log("✅ Usuarios del sistema Wessex Rugby creados exitosamente:");
      console.log("   - Directiva: directiva@ubiobio.cl / Directiva2024");
      console.log("   - Tesorera: tesorera@ubiobio.cl / Tesorera2024");
      console.log("   - Entrenador: entrenador@ubiobio.cl / Entrenador2024");
      console.log("   - Apoderado: apoderado@ubiobio.cl / Apoderado2024");

      // Mantener referencia para creación de otros datos
      const user1 = userDirectiva;
      const user2 = userTesorera;
      const user3 = userEntrenador;

    } else {
      console.log("✅ Usuarios del sistema ya existen, cargando referencias...");
      const user1 = await userRepository.findOneBy({ email: "directiva@ubiobio.cl" });
      const user2 = await userRepository.findOneBy({ email: "tesorera@ubiobio.cl" });
      const user3 = await userRepository.findOneBy({ email: "entrenador@ubiobio.cl" });
    }

    console.log("✅ Sistema Wessex Rugby inicializado correctamente");

  } catch (error) {
    console.error("❌ Error al crear datos iniciales:", error);
  }
}



export { createInitialData };
