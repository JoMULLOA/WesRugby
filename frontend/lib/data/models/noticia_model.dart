class NoticiaModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final DateTime fechaPublicacion;
  final String estado;
  final bool destacada;
  final int orden;
  final String rutCreador;
  final String nombreCreador;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  NoticiaModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.fechaPublicacion,
    required this.estado,
    required this.destacada,
    required this.orden,
    required this.rutCreador,
    required this.nombreCreador,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory NoticiaModel.fromJson(Map<String, dynamic> json) {
    return NoticiaModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagen: json['imagen']?.toString() ?? '',
      fechaPublicacion: DateTime.parse(
        json['fechaPublicacion'] ??
            DateTime.now().toIso8601String().split('T')[0],
      ),
      estado: json['estado']?.toString() ?? 'borrador',
      destacada: json['destacada'] ?? false,
      orden: json['orden'] ?? 0,
      rutCreador: json['rutCreador']?.toString() ?? '',
      nombreCreador: json['nombreCreador']?.toString() ?? '',
      fechaCreacion: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      fechaActualizacion: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'fechaPublicacion':
          fechaPublicacion.toIso8601String().split('T')[0], // Solo la fecha
      'estado': estado,
      'destacada': destacada,
      'orden': orden,
      'rutCreador': rutCreador,
      'nombreCreador': nombreCreador,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  NoticiaModel copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? imagen,
    DateTime? fechaPublicacion,
    String? estado,
    bool? destacada,
    int? orden,
    String? rutCreador,
    String? nombreCreador,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return NoticiaModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
      estado: estado ?? this.estado,
      destacada: destacada ?? this.destacada,
      orden: orden ?? this.orden,
      rutCreador: rutCreador ?? this.rutCreador,
      nombreCreador: nombreCreador ?? this.nombreCreador,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
