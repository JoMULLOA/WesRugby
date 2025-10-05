import { AppDataSource } from "./configDb.js";
import { encryptPassword } from "../helpers/bcrypt.helper.js";
import User from "../entity/user.entity.js";
import PaymentPlan from "../entity/paymentPlan.entity.js";
import Player from "../entity/player.entity.js";
import Enrollment from "../entity/enrollment.entity.js";
import Payment from "../entity/payment.entity.js";

function ensureInitialized() {
  if (!AppDataSource.isInitialized) {
    throw new Error("DataSource must be initialized before running createInitialData()");
  }
}

async function upsertUser(userRepository, { rut, email, fullName, role, phone }, password) {
  let user = await userRepository.findOne({ where: { email } });

  if (!user) {
    user = userRepository.create({
      rut,
      email,
      fullName,
      role,
      phone,
      password: await encryptPassword(password),
    });
    await userRepository.save(user);
  }

  return user;
}

async function createInitialData() {
  try {
    ensureInitialized();

    const userRepository = AppDataSource.getRepository(User);
    const planRepository = AppDataSource.getRepository(PaymentPlan);
    const playerRepository = AppDataSource.getRepository(Player);
    const enrollmentRepository = AppDataSource.getRepository(Enrollment);
    const paymentRepository = AppDataSource.getRepository(Payment);

    const [directiva, tesorera, entrenador, apoderado] = await Promise.all([
      upsertUser(userRepository, {
        rut: "12.345.678-9",
        email: "directiva@wessex.cl",
        fullName: "Tatiana Gutiérrez",
        role: "directiva",
        phone: "+56 9 1234 5678",
      }, "Directiva2024"),
      upsertUser(userRepository, {
        rut: "23.456.789-0",
        email: "tesorera@wessex.cl",
        fullName: "María López",
        role: "tesorera",
        phone: "+56 9 2345 6789",
      }, "Tesorera2024"),
      upsertUser(userRepository, {
        rut: "34.567.890-1",
        email: "entrenador@wessex.cl",
        fullName: "Diego Constanzo",
        role: "entrenador",
        phone: "+56 9 3456 7890",
      }, "Entrenador2024"),
      upsertUser(userRepository, {
        rut: "45.678.901-2",
        email: "apoderado@wessex.cl",
        fullName: "Luis Pereira",
        role: "apoderado",
        phone: "+56 9 4567 8901",
      }, "Apoderado2024"),
    ]);

    const planMensual = await planRepository.findOne({ where: { name: "Mensualidad 2025" } });
    let monthlyPlan = planMensual;
    if (!monthlyPlan) {
      monthlyPlan = planRepository.create({
        name: "Mensualidad 2025",
        amount: 25000,
        frequency: "mensual",
        isActive: true,
      });
      await planRepository.save(monthlyPlan);
    }

    const playerRut = "26.789.012-3";
    let player = await playerRepository.findOne({ where: { rut: playerRut } });
    if (!player) {
      player = playerRepository.create({
        rut: playerRut,
        firstName: "Tomás",
        lastName: "González",
        birthDate: "2015-04-12",
        gender: "masculino",
        schoolGrade: "6º Básico",
        guardian: apoderado,
      });
      await playerRepository.save(player);
    }

    let enrollment = await enrollmentRepository.findOne({
      where: { player: { id: player.id }, season: "2025" },
      relations: { player: true },
    });

    if (!enrollment) {
      enrollment = enrollmentRepository.create({
        season: "2025",
        status: "active",
        player,
        plan: monthlyPlan,
        createdBy: directiva,
        approvedBy: tesorera,
        approvedAt: new Date(),
      });
      await enrollmentRepository.save(enrollment);
    }

    const existingPayments = await paymentRepository.count({ where: { enrollment: { id: enrollment.id } } });
    if (existingPayments === 0) {
      const samplePayment = paymentRepository.create({
        enrollment,
        submittedBy: apoderado,
        method: "transferencia",
        amount: 25000,
        status: "validated",
        paidAt: "2025-03-01",
        dueDate: "2025-03-05",
        referenceCode: "WR-2025-0001",
        reviewedBy: tesorera,
        reviewedAt: new Date(),
      });
      await paymentRepository.save(samplePayment);
    }

    console.log("Base de datos inicializada con datos semilla para WesRugby");
  } catch (error) {
    console.error("Error al crear datos iniciales:", error);
  }
}

export { createInitialData };