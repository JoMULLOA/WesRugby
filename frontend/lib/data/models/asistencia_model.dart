import 'package:flutter/material.dart';

/// Modelo para representar un alumno en el sistema
class Alumno {
  final String rut;
  final String nombreCompleto;
  final String email;
  final String categoria; // Sub-18, Sub-16, Senior, etc.
  final String telefono;
  final bool activo;
  final DateTime? fechaInscripcion;

  Alumno({
    required this.rut,
    required this.nombreCompleto,
    required this.email,
    required this.categoria,
    this.telefono = '',
    this.activo = true,
    this.fechaInscripcion,
  });

  factory Alumno.fromJson(Map<String, dynamic> json) {
    return Alumno(
      rut: json['rut']?.toString() ?? '',
      nombreCompleto: json['nombreCompleto']?.toString() ?? 'Sin nombre',
      email: json['email']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Sin categoría',
      telefono: json['telefono']?.toString() ?? '',
      activo: json['activo'] ?? true,
      fechaInscripcion:
          json['fechaInscripcion'] != null
              ? DateTime.tryParse(json['fechaInscripcion'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rut': rut,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'categoria': categoria,
      'telefono': telefono,
      'activo': activo,
      'fechaInscripcion': fechaInscripcion?.toIso8601String(),
    };
  }
}

/// Enumeración para el estado de asistencia
enum EstadoAsistencia { presente, ausente, tardanza, justificado, sinRegistrar }

extension EstadoAsistenciaExtension on EstadoAsistencia {
  String get nombre {
    switch (this) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.tardanza:
        return 'Tardanza';
      case EstadoAsistencia.justificado:
        return 'Justificado';
      case EstadoAsistencia.sinRegistrar:
        return 'Sin registrar';
    }
  }

  Color get color {
    switch (this) {
      case EstadoAsistencia.presente:
        return const Color(0xFF057233); // Leaf Green
      case EstadoAsistencia.ausente:
        return const Color(0xFFB02A2E); // Crimson Alert
      case EstadoAsistencia.tardanza:
        return const Color(0xFFFF8C00); // Orange
      case EstadoAsistencia.justificado:
        return const Color(0xFF090976); // Deep Royal Blue
      case EstadoAsistencia.sinRegistrar:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData get icono {
    switch (this) {
      case EstadoAsistencia.presente:
        return Icons.check_circle;
      case EstadoAsistencia.ausente:
        return Icons.cancel;
      case EstadoAsistencia.tardanza:
        return Icons.access_time;
      case EstadoAsistencia.justificado:
        return Icons.info;
      case EstadoAsistencia.sinRegistrar:
        return Icons.help_outline;
    }
  }
}

/// Modelo para representar el registro de asistencia de un alumno
class RegistroAsistencia {
  final String rutAlumno;
  final String nombreAlumno;
  final EstadoAsistencia estado;
  final DateTime fechaHora;
  final String? observaciones;
  final String? justificacion;

  RegistroAsistencia({
    required this.rutAlumno,
    required this.nombreAlumno,
    required this.estado,
    required this.fechaHora,
    this.observaciones,
    this.justificacion,
  });

  factory RegistroAsistencia.fromJson(Map<String, dynamic> json) {
    return RegistroAsistencia(
      rutAlumno: json['rutAlumno']?.toString() ?? '',
      nombreAlumno: json['nombreAlumno']?.toString() ?? '',
      estado: EstadoAsistencia.values.firstWhere(
        (e) => e.name == json['estado']?.toString(),
        orElse: () => EstadoAsistencia.sinRegistrar,
      ),
      fechaHora:
          DateTime.tryParse(json['fechaHora']?.toString() ?? '') ??
          DateTime.now(),
      observaciones: json['observaciones']?.toString(),
      justificacion: json['justificacion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rutAlumno': rutAlumno,
      'nombreAlumno': nombreAlumno,
      'estado': estado.name,
      'fechaHora': fechaHora.toIso8601String(),
      'observaciones': observaciones,
      'justificacion': justificacion,
    };
  }

  RegistroAsistencia copyWith({
    EstadoAsistencia? estado,
    String? observaciones,
    String? justificacion,
  }) {
    return RegistroAsistencia(
      rutAlumno: rutAlumno,
      nombreAlumno: nombreAlumno,
      estado: estado ?? this.estado,
      fechaHora: fechaHora,
      observaciones: observaciones ?? this.observaciones,
      justificacion: justificacion ?? this.justificacion,
    );
  }
}

/// Modelo para representar una sesión de entrenamiento/clase
class SesionEntrenamiento {
  final String id;
  final String nombre;
  final String categoria;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String entrenadorRut;
  final String entrenadorNombre;
  final List<RegistroAsistencia> registros;
  final String? descripcion;
  final bool finalizada;

  SesionEntrenamiento({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.fechaInicio,
    this.fechaFin,
    required this.entrenadorRut,
    required this.entrenadorNombre,
    this.registros = const [],
    this.descripcion,
    this.finalizada = false,
  });

  factory SesionEntrenamiento.fromJson(Map<String, dynamic> json) {
    return SesionEntrenamiento(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      fechaInicio:
          DateTime.tryParse(json['fechaInicio']?.toString() ?? '') ??
          DateTime.now(),
      fechaFin:
          json['fechaFin'] != null
              ? DateTime.tryParse(json['fechaFin'].toString())
              : null,
      entrenadorRut: json['entrenadorRut']?.toString() ?? '',
      entrenadorNombre: json['entrenadorNombre']?.toString() ?? '',
      registros:
          (json['registros'] as List<dynamic>?)
              ?.map(
                (r) => RegistroAsistencia.fromJson(r as Map<String, dynamic>),
              )
              .toList() ??
          [],
      descripcion: json['descripcion']?.toString(),
      finalizada: json['finalizada'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'entrenadorRut': entrenadorRut,
      'entrenadorNombre': entrenadorNombre,
      'registros': registros.map((r) => r.toJson()).toList(),
      'descripcion': descripcion,
      'finalizada': finalizada,
    };
  }

  /// Obtiene estadísticas de la sesión
  EstadisticasAsistencia get estadisticas {
    final total = registros.length;
    if (total == 0) {
      return EstadisticasAsistencia(
        totalAlumnos: 0,
        presentes: 0,
        ausentes: 0,
        tardanzas: 0,
        justificados: 0,
        porcentajeAsistencia: 0.0,
      );
    }

    final presentes =
        registros.where((r) => r.estado == EstadoAsistencia.presente).length;
    final ausentes =
        registros.where((r) => r.estado == EstadoAsistencia.ausente).length;
    final tardanzas =
        registros.where((r) => r.estado == EstadoAsistencia.tardanza).length;
    final justificados =
        registros.where((r) => r.estado == EstadoAsistencia.justificado).length;

    final porcentaje = ((presentes + tardanzas) / total) * 100;

    return EstadisticasAsistencia(
      totalAlumnos: total,
      presentes: presentes,
      ausentes: ausentes,
      tardanzas: tardanzas,
      justificados: justificados,
      porcentajeAsistencia: porcentaje,
    );
  }
}

/// Modelo para las estadísticas de asistencia
class EstadisticasAsistencia {
  final int totalAlumnos;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final double porcentajeAsistencia;

  EstadisticasAsistencia({
    required this.totalAlumnos,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.justificados,
    required this.porcentajeAsistencia,
  });
}
