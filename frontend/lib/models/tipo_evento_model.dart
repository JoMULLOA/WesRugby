class TipoEvento {
  final String id;
  final String nombre;
  final bool esDeportivo;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  TipoEvento({
    required this.id,
    required this.nombre,
    required this.esDeportivo,
    required this.activo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory TipoEvento.fromJson(Map<String, dynamic> json) {
    return TipoEvento(
      id: json['id'],
      nombre: json['nombre'],
      esDeportivo: json['esDeportivo'],
      activo: json['activo'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'esDeportivo': esDeportivo,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TipoEvento{id: $id, nombre: $nombre, esDeportivo: $esDeportivo, activo: $activo}';
  }
}