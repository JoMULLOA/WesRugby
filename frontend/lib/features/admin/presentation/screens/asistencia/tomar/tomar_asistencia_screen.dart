import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';

class TomarAsistenciaScreen extends StatefulWidget {
  const TomarAsistenciaScreen({super.key});

  @override
  State<TomarAsistenciaScreen> createState() => _TomarAsistenciaScreenState();
}

class _TomarAsistenciaScreenState extends State<TomarAsistenciaScreen> {
  final EstudianteService _estudianteService = EstudianteService();
  final AsistenciaService _asistenciaService = AsistenciaService();

  // Estado de carga
  bool _isLoadingEstudiantes = false;
  bool _isSavingAsistencia = false;

  // Datos
  List<Map<String, dynamic>> _todosEstudiantes = [];
  List<String> _cursosDisponibles = [];
  String? _cursoSeleccionado;

  // Asistencia
  Map<String, String> _asistenciaEstudiantes = {}; // RUT -> estado
  final List<String> _estadosAsistencia = [
    'presente',
    'ausente',
    'justificado',
  ];

  // Formulario de sesión
  final _nombreSesionController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime _fechaSesion = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodosEstudiantes();
  }

  @override
  void dispose() {
    _nombreSesionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadTodosEstudiantes() async {
    try {
      setState(() {
        _isLoadingEstudiantes = true;
      });

      final estudiantes = await _estudianteService.getAllStudentsFromAPI();

      // Extraer cursos únicos
      final cursosSet = <String>{};
      for (var estudiante in estudiantes) {
        final curso = estudiante['curso'];
        if (curso != null && curso.toString().isNotEmpty) {
          cursosSet.add(curso.toString());
        }
      }

      setState(() {
        _todosEstudiantes = estudiantes;
        _cursosDisponibles = cursosSet.toList()..sort();
        _isLoadingEstudiantes = false;
      });

      if (kDebugMode) {
        print('📚 Estudiantes cargados: ${estudiantes.length}');
        print('📋 Cursos disponibles: $_cursosDisponibles');
      }
    } catch (e) {
      setState(() {
        _isLoadingEstudiantes = false;
      });
      if (kDebugMode) {
        print('Error al cargar estudiantes: $e');
      }
      _showErrorSnackBar('Error al cargar estudiantes');
    }
  }

  List<Map<String, dynamic>> _getEstudiantesPorCurso() {
    if (_cursoSeleccionado == null) return [];

    return _todosEstudiantes
        .where(
          (estudiante) =>
              estudiante['curso'] == _cursoSeleccionado &&
              estudiante['estado'] == 'activo',
        )
        .toList();
  }

  void _onCursoSelected(String? curso) {
    setState(() {
      _cursoSeleccionado = curso;
      _asistenciaEstudiantes.clear();

      // Inicializar asistencia como "presente" para todos los estudiantes del curso
      final estudiantes = _getEstudiantesPorCurso();
      for (var estudiante in estudiantes) {
        _asistenciaEstudiantes[estudiante['rut']] = 'presente';
      }
    });
  }

  void _cambiarAsistencia(String rut, String nuevoEstado) {
    setState(() {
      _asistenciaEstudiantes[rut] = nuevoEstado;
    });
  }

  Future<void> _guardarAsistencia() async {
    if (_cursoSeleccionado == null) {
      _showErrorSnackBar('Selecciona un curso');
      return;
    }

    if (_nombreSesionController.text.trim().isEmpty) {
      _showErrorSnackBar('Ingresa el nombre de la sesión');
      return;
    }

    if (_asistenciaEstudiantes.isEmpty) {
      _showErrorSnackBar('No hay estudiantes para registrar asistencia');
      return;
    }

    setState(() {
      _isSavingAsistencia = true;
    });

    try {
      // Obtener estudiantes del curso seleccionado para incluir nombres
      final estudiantesCurso = _getEstudiantesPorCurso();

      // Crear el objeto de sesión de asistencia
      final sesionAsistencia = {
        'nombre': _nombreSesionController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'fecha': _fechaSesion.toIso8601String(),
        'curso': _cursoSeleccionado,
        'asistencias':
            _asistenciaEstudiantes.entries
                .map(
                  (entry) => {
                    'rutEstudiante': entry.key,
                    'nombreEstudiante':
                        estudiantesCurso.firstWhere(
                          (e) => e['rut'] == entry.key,
                          orElse: () => {'nombre': 'Estudiante ${entry.key}'},
                        )['nombre'],
                    'estado': entry.value,
                  },
                )
                .toList(),
      };

      // Llamar al servicio para guardar en el backend
      await _asistenciaService.guardarSesionAsistencia(sesionAsistencia);

      if (kDebugMode) {
        print('✅ Asistencia guardada: $sesionAsistencia');
      }

      _showSuccessDialog();
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar asistencia: $e');
      }
      _showErrorSnackBar('Error al guardar la asistencia');
    } finally {
      setState(() {
        _isSavingAsistencia = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: WessexColors.leafGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Asistencia Guardada!',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'La asistencia de ${_cursoSeleccionado} ha sido registrada correctamente.',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context); // Volver al dashboard
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.leafGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Entendido',
                      style: TextStyle(
                        color: WessexColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Tomar Asistencia', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informativo
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.how_to_reg,
                          color: WessexColors.deepRoyalBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registro de Asistencia',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toma la asistencia de los estudiantes por curso',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Información de la sesión
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de la Sesión',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nombre de la sesión
                      TextFormField(
                        controller: _nombreSesionController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la Sesión *',
                          hintText: 'Ej: Entrenamiento Técnico',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(
                            Icons.sports_rugby,
                            color: WessexColors.deepRoyalBlue,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descripción (Opcional)',
                          hintText: 'Actividades realizadas en la sesión',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Fecha
                      InkWell(
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaSesion,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (fecha != null) {
                            setState(() {
                              _fechaSesion = fecha;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: WessexColors.leafGreen,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Fecha: ${_fechaSesion.day.toString().padLeft(2, '0')}/${_fechaSesion.month.toString().padLeft(2, '0')}/${_fechaSesion.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selección de curso
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Curso',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_isLoadingEstudiantes)
                        Center(
                          child: CircularProgressIndicator(
                            color: WessexColors.deepRoyalBlue,
                          ),
                        )
                      else if (_cursosDisponibles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: WessexColors.crimsonAlert.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: WessexColors.crimsonAlert.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: WessexColors.crimsonAlert,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No se encontraron cursos disponibles.',
                                  style: TextStyle(
                                    color: WessexColors.crimsonAlert,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _cursoSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Curso',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.class_,
                              color: WessexColors.crimsonAlert,
                            ),
                          ),
                          isExpanded: true,
                          hint: const Text('Selecciona un curso'),
                          items:
                              _cursosDisponibles
                                  .map(
                                    (curso) => DropdownMenuItem<String>(
                                      value: curso,
                                      child: Text(curso),
                                    ),
                                  )
                                  .toList(),
                          onChanged: _onCursoSelected,
                        ),
                    ],
                  ),
                ),

                // Lista de estudiantes para tomar asistencia
                if (_cursoSeleccionado != null) ...[
                  _buildListaAsistencia(),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: WessexColors.darkGrape),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: WessexColors.darkGrape,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              _isSavingAsistencia ? null : _guardarAsistencia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.leafGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isSavingAsistencia
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: WessexColors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Guardando...',
                                        style: TextStyle(
                                          color: WessexColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    'Guardar Asistencia',
                                    style: TextStyle(
                                      color: WessexColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListaAsistencia() {
    final estudiantes = _getEstudiantesPorCurso();

    if (estudiantes.isEmpty) {
      return WessexCard(
        margin: const EdgeInsets.only(bottom: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info, color: WessexColors.deepRoyalBlue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay estudiantes activos en este curso.',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estudiantes - $_cursoSeleccionado',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${estudiantes.length} estudiantes',
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botones rápidos
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (var estudiante in estudiantes) {
                        _asistenciaEstudiantes[estudiante['rut']] = 'presente';
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: WessexColors.leafGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Todos Presentes',
                    style: TextStyle(
                      color: WessexColors.leafGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (var estudiante in estudiantes) {
                        _asistenciaEstudiantes[estudiante['rut']] = 'ausente';
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: WessexColors.crimsonAlert),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Todos Ausentes',
                    style: TextStyle(
                      color: WessexColors.crimsonAlert,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de estudiantes
          ...estudiantes.asMap().entries.map((entry) {
            final estudiante = entry.value;
            final rut = estudiante['rut'];
            final estadoAsistencia = _asistenciaEstudiantes[rut] ?? 'presente';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _getColorByEstado(estadoAsistencia).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
                color: _getColorByEstado(estadoAsistencia).withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${estudiante['nombre']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'RUT: ${estudiante['rut']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _getIconByEstado(estadoAsistencia),
                        color: _getColorByEstado(estadoAsistencia),
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children:
                        _estadosAsistencia.map((estado) {
                          final isSelected = estadoAsistencia == estado;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: OutlinedButton(
                                onPressed:
                                    () => _cambiarAsistencia(rut, estado),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      isSelected
                                          ? _getColorByEstado(estado)
                                          : Colors.transparent,
                                  side: BorderSide(
                                    color: _getColorByEstado(estado),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  _getLabelByEstado(estado),
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : _getColorByEstado(estado),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getColorByEstado(String estado) {
    switch (estado) {
      case 'presente':
        return WessexColors.leafGreen;
      case 'ausente':
        return WessexColors.crimsonAlert;
      case 'justificado':
        return WessexColors.deepRoyalBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconByEstado(String estado) {
    switch (estado) {
      case 'presente':
        return Icons.check_circle;
      case 'ausente':
        return Icons.cancel;
      case 'justificado':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  String _getLabelByEstado(String estado) {
    switch (estado) {
      case 'presente':
        return 'Presente';
      case 'ausente':
        return 'Ausente';
      case 'justificado':
        return 'Justificado';
      default:
        return 'Desconocido';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.crimsonAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
