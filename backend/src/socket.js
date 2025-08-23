// src/socket.js
import { Server } from "socket.io";
import jwt from "jsonwebtoken";
import { ACCESS_TOKEN_SECRET } from "./config/configEnv.js";

let io;

// Función para obtener la instancia de Socket.io
export function getSocketInstance() {
  return io;
}

export function initializeSocket(server) {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
      credentials: true
    }
  });

  console.log("🚀 Socket.IO inicializado");

  // Middleware de autenticación
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    
    if (!token) {
      console.error("❌ Token no proporcionado en socket");
      return next(new Error("Authentication error: Token not provided"));
    }

    try {
      const decoded = jwt.verify(token, ACCESS_TOKEN_SECRET);
      socket.userId = decoded.rut;
      console.log(`✅ Socket autenticado para usuario: ${socket.userId}`);
      next();
    } catch (error) {
      console.error("❌ Error de autenticación en socket:", error.message);
      return next(new Error("Authentication error: Invalid token"));
    }
  });

  io.on("connection", (socket) => {
    console.log(`🔌 Usuario conectado: ${socket.id} (RUT: ${socket.userId})`);
    
    // Unirse a sala personal del usuario
    socket.join(`usuario_${socket.userId}`);
    console.log(`👤 Usuario ${socket.userId} unido a su sala personal`);

    socket.on("reconectar_usuario", () => {
      socket.join(`usuario_${socket.userId}`);
      console.log(`🔄 Usuario ${socket.userId} reconectado y reregistrado`);
    });

    socket.on("disconnect", () => {
      console.log(`🔌 Usuario desconectado: ${socket.id} (RUT: ${socket.userId})`);
    });
  });

  return io;
}

// Función para enviar mensajes desde otros servicios
export function emitToUser(rutUsuario, event, data) {
  if (io) {
    io.to(`usuario_${rutUsuario}`).emit(event, data);
  }
}

export { io };