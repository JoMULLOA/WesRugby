import passport from "passport";
import { ExtractJwt, Strategy as JwtStrategy } from "passport-jwt";
import User from "../entity/user.entity.js";
import { ACCESS_TOKEN_SECRET } from "../config/configEnv.js";
import { AppDataSource } from "../config/configDb.js";

const options = {
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  secretOrKey: ACCESS_TOKEN_SECRET,
};

passport.use(
  new JwtStrategy(options, async (jwtPayload, done) => {
    try {
      const userRepository = AppDataSource.getRepository(User);

      let user = null;
      if (jwtPayload?.id) {
        user = await userRepository.findOne({ where: { id: jwtPayload.id } });
      }

      if (!user && jwtPayload?.rut) {
        user = await userRepository.findOne({ where: { rut: jwtPayload.rut } });
      }

      if (!user && jwtPayload?.email) {
        user = await userRepository.findOne({ where: { email: jwtPayload.email } });
      }

      if (!user) {
        return done(null, false);
      }

      // Alias temporales para compatibilidad con código existente
      user.rol = user.role;
      user.nombreCompleto = user.fullName;

      return done(null, user);
    } catch (error) {
      console.error("Error en estrategia JWT:", error);
      return done(error, false);
    }
  })
);

export function passportJwtSetup() {
  passport.initialize();
}