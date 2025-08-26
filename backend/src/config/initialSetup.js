"use strict";
import User from "../entity/user.entity.js";
import Vehiculo from "../entity/vehiculo.entity.js";
import Amistad from "../entity/amistad.entity.js";
import Reporte from "../entity/reporte.entity.js";
import { AppDataSource } from "./configDb.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";

// Función para calcular dígito verificador del RUT
function calcularDV(rut) {
  let suma = 0;
  let multiplicador = 2;
  
  // Calcular desde derecha a izquierda
  while (rut > 0) {
    suma += (rut % 10) * multiplicador;
    rut = Math.floor(rut / 10);
    multiplicador = multiplicador < 7 ? multiplicador + 1 : 2;
  }
  
  const resto = suma % 11;
  const dv = 11 - resto;
  
  if (dv === 11) return '0';
  if (dv === 10) return 'K';
  return dv.toString();
}

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
        email: "apoderado@alumnos.ubiobio.cl",
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
      console.log("   - Apoderado: apoderado@alumnos.ubiobio.cl / Apoderado2024");

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

    // Crear Vehículos solo para usuarios con rol de directiva (ejemplo)
    const vehiculoRepository = AppDataSource.getRepository(Vehiculo);
    const vehiculoCount = await vehiculoRepository.count();
    
    if (vehiculoCount === 0) {
      console.log("🚗 Creando vehículo de ejemplo para directiva...");
      
      const userDirectiva = await userRepository.findOneBy({ email: "directiva@ubiobio.cl" });
      
      if (userDirectiva) {
        const vehiculoDirectiva = vehiculoRepository.create({
          patente: "WXRG12",
          tipo: "Auto",
          marca: "Toyota",
          modelo: "Toyota RAV4",
          año: 2023,
          color: "Blanco",
          nro_asientos: 5,
          tipoCombustible: "hibrido",
          documentacion: "Permiso de circulación vigente y seguro obligatorio",
          propietario: userDirectiva,
        });
        
        await vehiculoRepository.save(vehiculoDirectiva);
        console.log("✅ Vehículo de ejemplo creado para directiva");
      }
    }

  } catch (error) {
    console.error("❌ Error al crear datos iniciales:", error);
  }
}

async function createInitialReports() {
  try {
    const reporteRepository = AppDataSource.getRepository(Reporte);
    const reporteCount = await reporteRepository.count();
    
    if (reporteCount === 0) {
      console.log("* => Creando reportes de ejemplo...");
      
      // No crear reportes de ejemplo por defecto
      // Solo configurar la estructura
      console.log("* => Sistema de reportes configurado correctamente");
    } else {
      console.log("* => Sistema de reportes ya configurado");
    }
  } catch (error) {
    console.error("❌ Error al configurar sistema de reportes:", error);
  }
}

// Función para crear tarjetas de sandbox para pruebas
async function createSandboxCards() {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const todosLosUsuarios = await userRepository.find({
      where: { rol: "estudiante" }
    });

    console.log("🃏 Asignando tarjetas a usuarios...");
    
    const bancos = [
      "Banco de Chile", "BancoEstado", "Santander", "BCI", "Banco Falabella",
      "Banco Ripley", "Banco Security", "Banco Consorcio", "Banco Itaú",
      "Banco de Crédito e Inversiones", "Banco Paris", "Banco Bice"
    ];

    // =============== ASIGNAR TARJETAS A TODOS LOS USUARIOS ===============
    console.log("🎯 Creando y asignando tarjetas específicas para todos los usuarios...");
    
    const usuariosConTarjetas = [];
    
    for (let i = 0; i < todosLosUsuarios.length; i++) {
      const usuario = todosLosUsuarios[i];
      
      // Determinar tipo de tarjeta basado en el número de usuario
      let tipo, numeroBase;
      if (i % 3 === 0) {
        tipo = "visa";
        numeroBase = "4" + String(Math.floor(Math.random() * 999999999999999)).padStart(15, '0');
      } else if (i % 3 === 1) {
        tipo = "mastercard";
        numeroBase = "5" + String(Math.floor(Math.random() * 999999999999999)).padStart(15, '0');
      } else {
        tipo = "american_express";
        numeroBase = "3" + String(Math.floor(Math.random() * 99999999999999)).padStart(14, '0');
      }
      
      // Formatear número de tarjeta
      const numeroFormateado = numeroBase.replace(/(.{4})/g, '$1-').slice(0, -1);
      
      // Generar fecha de vencimiento (entre 2025 y 2030)
      const año = 2025 + (i % 6);
      const mes = (i % 12) + 1;
      const fechaVencimiento = `${mes.toString().padStart(2, '0')}/${año}`;
      
      // Generar CVV
      const cvv = tipo === "american_express" 
        ? String(Math.floor(Math.random() * 9999)).padStart(4, '0')
        : String(Math.floor(Math.random() * 999)).padStart(3, '0');
      
      // Límite de crédito aleatorio
      const limites = [100000, 200000, 300000, 500000, 750000, 1000000];
      const limiteCredito = limites[i % limites.length];
      
      const banco = bancos[i % bancos.length];

      // Crear objeto tarjeta para el usuario
      const tarjeta = {
        id: `tarjeta_${i + 1}`,
        numero: numeroFormateado,
        nombreTitular: usuario.nombreCompleto,
        fechaVencimiento,
        cvv,
        tipo,
        banco,
        limiteCredito,
        activa: true,
        fechaCreacion: new Date().toISOString()
      };

      // Asignar tarjeta al usuario
      usuario.tarjetas = [tarjeta];
      usuariosConTarjetas.push(usuario);
      
      // Guardar en lotes de 25 para mejor rendimiento
      if (usuariosConTarjetas.length === 25 || i === todosLosUsuarios.length - 1) {
        await userRepository.save(usuariosConTarjetas);
        console.log(`   💳 Tarjetas asignadas a usuarios ${i - usuariosConTarjetas.length + 2} al ${i + 1}`);
        usuariosConTarjetas.length = 0; // Limpiar array
      }
    }

    console.log(`✅ Se asignaron ${todosLosUsuarios.length} tarjetas exitosamente`);
    console.log(`   💳 Una tarjeta por cada usuario estudiante`);
    
  } catch (error) {
    console.error("❌ Error al asignar tarjetas a usuarios:", error);
  }
}

export { createInitialData };
