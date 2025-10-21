class AuspiciadorModel {
  final String id;
  final String titulo;
  final String imagen;
  final String? enlace;
  final String estado;
  final int orden;
  final String rutCreador;
  final String nombreCreador;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  AuspiciadorModel({
    required this.id,
    required this.titulo,
    required this.imagen,
    this.enlace,
    required this.estado,
    required this.orden,
    required this.rutCreador,
    required this.nombreCreador,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory AuspiciadorModel.fromJson(Map<String, dynamic> json) {
    return AuspiciadorModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      imagen: json['imagen']?.toString() ?? '',
      enlace: json['enlace']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      orden: json['orden'] ?? 0,
      rutCreador: json['rutCreador']?.toString() ?? '',
      nombreCreador: json['nombreCreador']?.toString() ?? '',
      fechaCreacion: DateTime.parse(
        json['createdAt'] ??
            json['fechaCreacion'] ??
            DateTime.now().toIso8601String(),
      ),
      fechaActualizacion: DateTime.parse(
        json['updatedAt'] ??
            json['fechaActualizacion'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
      'enlace': enlace,
      'estado': estado,
      'orden': orden,
      'rutCreador': rutCreador,
      'nombreCreador': nombreCreador,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  AuspiciadorModel copyWith({
    String? id,
    String? titulo,
    String? imagen,
    String? enlace,
    String? estado,
    int? orden,
    String? rutCreador,
    String? nombreCreador,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return AuspiciadorModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      imagen: imagen ?? this.imagen,
      enlace: enlace ?? this.enlace,
      estado: estado ?? this.estado,
      orden: orden ?? this.orden,
      rutCreador: rutCreador ?? this.rutCreador,
      nombreCreador: nombreCreador ?? this.nombreCreador,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
