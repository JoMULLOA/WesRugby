class MerchandisingModel {
  final String id;
  final String titulo;
  final String imagen;
  final double precio;
  final String? descripcion;
  final String estado;
  final int orden;
  final String rutCreador;
  final String nombreCreador;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  MerchandisingModel({
    required this.id,
    required this.titulo,
    required this.imagen,
    required this.precio,
    this.descripcion,
    required this.estado,
    required this.orden,
    required this.rutCreador,
    required this.nombreCreador,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory MerchandisingModel.fromJson(Map<String, dynamic> json) {
    return MerchandisingModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      imagen: json['imagen']?.toString() ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      descripcion: json['descripcion']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      orden: json['orden'] ?? 0,
      rutCreador: json['rutCreador']?.toString() ?? '',
      nombreCreador: json['nombreCreador']?.toString() ?? '',
      fechaCreacion: DateTime.parse(json['createdAt'] ?? json['fechaCreacion'] ?? DateTime.now().toIso8601String()),
      fechaActualizacion: DateTime.parse(json['updatedAt'] ?? json['fechaActualizacion'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
      'precio': precio,
      'descripcion': descripcion,
      'estado': estado,
      'orden': orden,
      'rutCreador': rutCreador,
      'nombreCreador': nombreCreador,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  MerchandisingModel copyWith({
    String? id,
    String? titulo,
    String? imagen,
    double? precio,
    String? descripcion,
    String? estado,
    int? orden,
    String? rutCreador,
    String? nombreCreador,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return MerchandisingModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      imagen: imagen ?? this.imagen,
      precio: precio ?? this.precio,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      orden: orden ?? this.orden,
      rutCreador: rutCreador ?? this.rutCreador,
      nombreCreador: nombreCreador ?? this.nombreCreador,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  // Formatear precio como string con moneda
  String get precioFormateado => '\$${precio.toStringAsFixed(0)}';
}