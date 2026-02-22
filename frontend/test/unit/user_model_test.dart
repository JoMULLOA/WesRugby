import 'package:flutter_test/flutter_test.dart';
import 'package:wesrugby/data/models/user_models.dart';

void main() {
  group('User.fromJson', () {
    final Map<String, dynamic> validJson = {
      'rut': '12.345.678-9',
      'nombreCompleto': 'Juan Pablo García',
      'email': 'juan.garcia@wessex.cl',
      'rol': 'apoderado',
    };

    test('parsea todos los campos correctamente', () {
      final user = User.fromJson(validJson);
      expect(user.rut, '12.345.678-9');
      expect(user.nombreCompleto, 'Juan Pablo García');
      expect(user.email, 'juan.garcia@wessex.cl');
      expect(user.rol, 'apoderado');
    });

    test('usa valor por defecto cuando rut es null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['rut'] = null;
      final user = User.fromJson(json);
      expect(user.rut, '');
    });

    test('usa valor por defecto cuando nombreCompleto es null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['nombreCompleto'] = null;
      final user = User.fromJson(json);
      expect(user.nombreCompleto, 'Usuario sin nombre');
    });

    test('usa valor por defecto cuando email es null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['email'] = null;
      final user = User.fromJson(json);
      expect(user.email, 'Sin email');
    });

    test('usa valor por defecto cuando rol es null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['rol'] = null;
      final user = User.fromJson(json);
      expect(user.rol, 'usuario');
    });

    test('convierte valores numéricos a string', () {
      final json = Map<String, dynamic>.from(validJson);
      json['rut'] = 12345;
      final user = User.fromJson(json);
      expect(user.rut, '12345');
    });

    test('acepta distintos roles válidos', () {
      for (final rol in ['directiva', 'tesorera', 'apoderado', 'entrenador']) {
        final json = Map<String, dynamic>.from(validJson);
        json['rol'] = rol;
        final user = User.fromJson(json);
        expect(user.rol, rol);
      }
    });
  });
}
